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
module PastPapers
  ROOT = Rails.root.join("db/seeds/past")
  IMAGES = Rails.root.join("db/seeds/images/past")

  # Older papers print no time limit and no points. They are sat in the time
  # the competition gives today and scored as a share of the tasks, not in
  # points nobody published.
  DEFAULT_MINUTES = 90

  Paper = Struct.new(:competition, :grade, :year, :minutes, :instructions, :tasks, :skipped, keyword_init: true)

  NotFound = Class.new(StandardError)

  module_function

  def file(slug, grade, year) = ROOT.join(slug.to_s, grade.to_s, "#{year}.yml")

  def find(slug, grade, year)
    path = file(slug, grade, year)
    raise NotFound, "#{slug} #{grade} #{year}" unless path.exist?

    data = YAML.safe_load_file(path)
    paper = data.fetch("paper")
    Paper.new(competition: slug.to_s, grade: grade.to_i, year: year.to_i, minutes: paper["minutes"] || DEFAULT_MINUTES,
              instructions: paper["instructions"], tasks: paper["tasks"], skipped: Array(data["skipped"]))
  end

  # The papers a student could sit: those whose problems are in the bank and
  # published, newest first. Grades only where the competition has them.
  def available(slug, grade: nil)
    scope = originals(slug)
    scope = scope.where("questions.source ->> 'grade' = ?", grade.to_s) if grade
    scope.group(Arel.sql("questions.source ->> 'grade'"), Arel.sql("questions.source ->> 'year'")).count
         .map { |(paper_grade, year), count| [ paper_grade.to_i, year.to_i, count ] }
         .sort_by { |paper_grade, year, _| [ paper_grade, -year ] }
  end

  def grades(slug) = originals(slug).distinct.pluck(Arel.sql("questions.source ->> 'grade'")).map(&:to_i).sort

  def originals(slug)
    Question.published.where("questions.source ->> 'competition' = ? AND questions.source ->> 'kind' = 'original'", slug.to_s)
  end

  # The paper's problems in its own order: 1, 2, … 12, 13а, 13б.
  def questions(slug, grade, year)
    originals(slug).where("questions.source ->> 'grade' = ? AND questions.source ->> 'year' = ?", grade.to_s, year.to_s)
                   .sort_by { |question| number_key(question.source["number"]) }
  end

  def number_key(number) = [ number.to_s.to_i, number.to_s.sub(/\A\d+/, "") ]

  def start!(user:, event:, grade:, year:)
    find(event.slug, grade, year) # the paper must exist as a file: its clock comes from there
    rows = questions(event.slug, grade, year)
    raise NotFound, "#{event.slug} #{grade} #{year}: no problems" if rows.empty?

    assignment = Assignment.build(user: user, kind: :mock, competition_slug: event.slug,
                                  paper_year: year, paper_grade: grade, feedback_after_answer: false)
    rows.each_with_index { |question, index| assignment.assignment_questions.build(question: question, position: index + 1) }
    assignment.save!
    assignment
  end

  def paper_for(assignment)
    return unless assignment.paper_year

    find(assignment.competition_slug, assignment.paper_grade, assignment.paper_year)
  end

  # Turns one paper file into rows for ProblemSeeds.import: the source on each,
  # the figure's path under IMAGES.
  def problems_from(path)
    slug, grade, year = path.relative_path_from(ROOT).to_s.delete_suffix(".yml").split("/")
    data = YAML.safe_load_file(path)
    data.fetch("problems").map do |problem|
      row = problem.except("source", "note", "image")
      # `status: draft` holds a problem back — an official key we believe is
      # wrong stays in the file, with its `note`, until someone checks the
      # printed paper.
      row["status"] = problem.fetch("status", "published")
      row["source"] = {
        "kind" => "original", "competition" => slug, "grade" => grade.to_i, "year" => year.to_i,
        "number" => problem.dig("source", "number").to_s, "points" => problem.dig("source", "points"),
        "task" => problem.dig("source", "kind")
      }
      if problem["image"].present?
        row["image"] = IMAGES.join(slug, grade, problem["image"]).relative_path_from(Rails.root).to_s
        row["image_filename"] = problem["image"]
      end
      row
    end
  end

  # Ours, written on the model of one paper's problems — easy, medium and hard
  # of each type, so a child meets the idea gently before the paper's level:
  # `<year>-modelled.yml` beside the paper. Labelled „По модела на задача 5 ·
  # СМТ 2024, 3 клас" and drawn into that competition's practice.
  def modelled_from(path)
    slug, grade, name = path.relative_path_from(ROOT).to_s.delete_suffix(".yml").split("/")
    year = name.delete_suffix("-modelled")
    # Ours inherit the problem type of the paper task they are modelled on.
    paper = path.dirname.join("#{year}.yml")
    types = paper.exist? ? YAML.safe_load_file(paper).fetch("problems").to_h { |row| [ row.dig("source", "number").to_s, row["type"] ] } : {}
    YAML.safe_load_file(path).map do |problem|
      inherited = types[problem["modelled_on"].to_s]
      problem = problem.merge("type" => inherited) if inherited && !problem.key?("type")
      problem.except("modelled_on", "level").merge(
        "status" => "published",
        "source" => { "kind" => "modelled", "competition" => slug, "grade" => grade.to_i, "year" => year.to_i,
                      "number" => problem["modelled_on"].to_s, "level" => problem["level"] }
      )
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
