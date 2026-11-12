# Past papers of real competitions and МОН exams — „Минали теми". Each paper
# is one file, `db/seeds/past/<competition slug>/<grade>/<year>.yml`, written
# by reading the published paper page by page: the paper's own minutes and
# instructions, and its problems word for word with the official answers, a
# worked explanation and the points the paper gives each task. A task the app
# cannot grade (a written proof, several answers, a drawing) is listed under
# `skipped` with the reason, so a paper's gaps are on the record.
#
# Every problem imported from one carries `questions.source` — kind
# "original", the competition, year, grade, task number, its points and its
# kind (choice / short / written) — which is what the label on the problem
# reads („СМТ 2024 · 3 клас · задача 5") and what a paper is rebuilt from.
# The label names the organiser's competition or exam, never the site the
# paper was found on.
#
# Sitting a paper is a mock assignment (MockExam) that also names its year and
# grade: the paper's minutes, its tasks in its order, scored in its points.
#
# A competition with several rounds a year (Математика без граници: autumn,
# winter, spring, …) files each round as `<year>-<round>.yml`, the round one
# of ROUNDS, and the round is part of the paper's identity everywhere — the
# problems' `source`, the assignment's `paper_round`, the links. A file with
# no round is the competition's MAIN_ROUND: the bank held one round a year
# before it held several, and its 700 live problems keep the source they had.
module PastPapers
  ROOT = Rails.root.join("db/seeds/past")
  IMAGES = Rails.root.join("db/seeds/images/past")

  # Older papers print no time limit and no points. They are sat in the time
  # the competition gives today and scored as a share of the tasks, not in
  # points nobody published.
  DEFAULT_MINUTES = 90

  Paper = Struct.new(:competition, :grade, :year, :round, :minutes, :instructions, :tasks, :skipped, keyword_init: true)

  # Rounds by the month they are sat in, which orders a year's papers newest
  # first. The names are in the locales (past_papers.rounds).
  ROUNDS = { "zima" => 2, "prolet" => 4, "polufinal" => 5, "final" => 6, "shtafeti" => 6, "esen" => 11 }.freeze

  # The round a file without one is, per competition.
  MAIN_ROUND = { "matematika-bez-granitsi" => "prolet" }.freeze

  NotFound = Class.new(StandardError)

  module_function

  # A round named in a request or a file: one of ROUNDS, or nil.
  def round(value) = ROUNDS.key?(value.to_s) ? value.to_s : nil

  # The round a paper or a problem's source is, the main one included: what
  # its label names. nil for a competition of one round a year.
  def round_of(slug, round) = round.presence || MAIN_ROUND[slug.to_s]

  def stem(year, round) = [ year, round(round) ].compact.join("-")

  # „2025", or „2025 · Есен" for a competition of several rounds a year (its
  # main round named too, so spring and autumn read alike): the year that a
  # paper's title, a problem's label and an unfinished session name.
  def edition(slug, year, round)
    named = round_of(slug, round)
    named ? "#{year} · #{I18n.t("past_papers.rounds.#{named}")}" : year.to_s
  end

  def file(slug, grade, year, round = nil) = ROOT.join(slug.to_s, grade.to_s, "#{stem(year, round)}.yml")

  def find(slug, grade, year, round = nil)
    path = file(slug, grade, year, round)
    raise NotFound, "#{slug} #{grade} #{stem(year, round)}" unless path.exist?

    data = YAML.safe_load_file(path, permitted_classes: [ Date ])
    paper = data.fetch("paper")
    Paper.new(competition: slug.to_s, grade: grade.to_i, year: year.to_i, round: round(round), minutes: paper["minutes"] || DEFAULT_MINUTES,
              instructions: paper["instructions"], tasks: paper["tasks"], skipped: Array(data["skipped"]))
  end

  # The papers a student could sit: those whose problems are in the bank and
  # published, newest first, as [grade, year, count, round]. Grades only where
  # the competition has them.
  def available(slug, grade: nil)
    scope = originals(slug)
    scope = scope.where("questions.source ->> 'grade' = ?", grade.to_s) if grade
    scope.group(Arel.sql("questions.source ->> 'grade'"), Arel.sql("questions.source ->> 'year'"), Arel.sql("questions.source ->> 'round'")).count
         .map { |(paper_grade, year, round), count| [ paper_grade.to_i, year.to_i, count, round ] }
         .sort_by { |paper_grade, year, _, round| [ paper_grade, -year, -ROUNDS.fetch(round_of(slug, round).to_s, 0) ] }
  end

  def grades(slug) = originals(slug).distinct.pluck(Arel.sql("questions.source ->> 'grade'")).map(&:to_i).sort

  def originals(slug)
    Question.published.where("questions.source ->> 'competition' = ? AND questions.source ->> 'kind' = 'original'", slug.to_s)
  end

  # The paper's problems in its own order: 1, 2, … 12, 13а, 13б.
  def questions(slug, grade, year, round = nil)
    scope = originals(slug).where("questions.source ->> 'grade' = ? AND questions.source ->> 'year' = ?", grade.to_s, year.to_s)
    scope = round(round) ? scope.where("questions.source ->> 'round' = ?", round(round)) : scope.where("questions.source ->> 'round' IS NULL")
    scope.sort_by { |question| number_key(question.source["number"]) }
  end

  def number_key(number) = [ number.to_s.to_i, number.to_s.sub(/\A\d+/, "") ]

  def start!(user:, event:, grade:, year:, round: nil)
    round = round(round)
    find(event.slug, grade, year, round) # the paper must exist as a file: its clock comes from there
    if (current = MockExam.running(user, event.slug, year: year, grade: grade, round: round))
      return current
    end

    rows = questions(event.slug, grade, year, round)
    raise NotFound, "#{event.slug} #{grade} #{stem(year, round)}: no problems" if rows.empty?

    assignment = Assignment.build(user: user, kind: :mock, competition_slug: event.slug,
                                  paper_year: year, paper_grade: grade, paper_round: round, feedback_after_answer: false)
    rows.each_with_index { |question, index| assignment.assignment_questions.build(question: question, position: index + 1) }
    assignment.save!
    assignment
  end

  def paper_for(assignment)
    return unless assignment.paper_year

    find(assignment.competition_slug, assignment.paper_grade, assignment.paper_year, assignment.paper_round)
  end

  # Turns one paper file into rows for ProblemSeeds.import: the source on each,
  # the figure's path under IMAGES.
  def problems_from(path)
    slug, grade, name = path.relative_path_from(ROOT).to_s.delete_suffix(".yml").split("/")
    year, round = split_stem(name)
    data = YAML.safe_load_file(path, permitted_classes: [ Date ])
    data.fetch("problems").map do |problem|
      row = problem.except("source", "note", "image", "figure")
      # `status: draft` holds a problem back — an official key we believe is
      # wrong stays in the file, with its `note`, until someone checks the
      # printed paper.
      row["status"] = problem.fetch("status", "published")
      row["source"] = {
        "kind" => "original", "competition" => slug, "grade" => grade.to_i, "year" => year.to_i,
        "number" => problem.dig("source", "number").to_s, "points" => problem.dig("source", "points"),
        "task" => problem.dig("source", "kind")
      }
      # Only a round of its own: a main-round problem keeps the source it had.
      row["source"]["round"] = round if round
      attach(row, slug, grade, problem["image"] || (figure_file(name, problem.dig("source", "number")) if problem["figure"]))
    end
  end

  # „2025-esen" → [2025, "esen"], „2025" → [2025, nil]. A suffix that is not a
  # round is refused rather than read as one: it would file a paper nobody
  # can link to.
  def split_stem(name)
    year, round = name.to_s.split("-", 2)
    raise ArgumentError, "#{name}: unknown round #{round.inspect}" if round && round(round).nil?

    [ year.to_i, round ]
  end

  # A drawn figure (tools/authoring/past_figures.rb) is named by the paper —
  # its year, and its round where it has one — the task and, for ours, the
  # level it belongs to.
  def figure_file(stem, number, level = nil) = "#{[ "fig", stem, number, level ].compact.join("-")}.png"

  def attach(row, slug, grade, image)
    return row if image.blank?

    row.merge("image" => IMAGES.join(slug, grade.to_s, image).relative_path_from(Rails.root).to_s, "image_filename" => image)
  end

  # Ours, written on the model of one paper's problems — easy, medium and hard
  # of each type, so a child meets the idea gently before the paper's level:
  # `<year>-modelled.yml` beside the paper. Labelled „По модела на задача 5 ·
  # СМТ 2024, 3 клас" and drawn into that competition's practice.
  def modelled_from(path)
    slug, grade, name = path.relative_path_from(ROOT).to_s.delete_suffix(".yml").split("/")
    paper_stem = name.delete_suffix("-modelled")
    year, round = split_stem(paper_stem)
    # Ours inherit the problem type of the paper task they are modelled on.
    paper = path.dirname.join("#{paper_stem}.yml")
    types = paper.exist? ? YAML.safe_load_file(paper, permitted_classes: [ Date ]).fetch("problems").to_h { |row| [ row.dig("source", "number").to_s, row["type"] ] } : {}
    YAML.safe_load_file(path, permitted_classes: [ Date ]).map do |problem|
      inherited = types[problem["modelled_on"].to_s]
      problem = problem.merge("type" => inherited) if inherited && !problem.key?("type")
      row = problem.except("modelled_on", "level", "figure", "image").merge(
        "status" => "published",
        "source" => { "kind" => "modelled", "competition" => slug, "grade" => grade.to_i, "year" => year,
                      "number" => problem["modelled_on"].to_s, "level" => problem["level"], "round" => round }.compact
      )
      attach(row, slug, grade, problem["image"] || (figure_file(paper_stem, problem["modelled_on"], problem["level"]) if problem["figure"]))
    end
  end

  def import_all(root: ROOT)
    topics = Topic.all.index_by(&:name)
    Pathname.glob(root.join("**/*.yml")).sort.sum(0) do |path|
      rows = path.basename.to_s.end_with?("-modelled.yml") ? modelled_from(path) : problems_from(path)
      ProblemSeeds.import(rows, topics)
      rows.size
    end
  end
end
