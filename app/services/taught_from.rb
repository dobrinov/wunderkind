# The school grade that first teaches a problem — stored as
# questions.taught_from_grade and read by one thing only, Dispatcher's grade
# hold. It is the per-problem half of the hold: Curriculum::TOPICS says when
# school reaches a *topic*, but „Числа и редици" holds tens and units and
# negative temperatures alike, and a second-grader in the review was served
# both, plus a triangle's angle sum and a 17 × 12 table, from topics school
# had reached.
#
# Three sources, in the order they are tried:
#
# - a past paper's problem, or one written on its model, belongs to the grade
#   the paper was set for (`source.grade`);
# - a ladder problem takes its family's grade from config/problem_type_grades.yml
#   (a person's reading of the МОН programme), rung by rung where the family
#   grows from one grade's numbers into the next; a family not listed there
#   takes the first grade that lists its topic;
# - an arithmetic fact is read off its own two numbers (FACT).
#
# Anything else — the hand-written batches — has none, and is held by its
# topic alone.
module TaughtFrom
  FILE = Rails.root.join("config/problem_type_grades.yml")

  # „Колко е 47 + 38?" — the arithmetic facts file (db/seeds/arithmetic_facts.yml).
  FACT = /\AКолко е (\d+) ([+−\-·×:]) (\d+)\?\z/

  module_function

  def map
    @map ||= YAML.safe_load_file(FILE)
  end

  def reset! = @map = nil

  # The grade for one problem row of a problem file. `rungs` is the sorted
  # list of distinct ratings of the row's family *in the file* — a question's
  # rating in the database moves with every answer, its rung does not.
  def for_row(problem, rungs: nil)
    source_grade(problem["source"]) || family_grade(problem["family"], problem["topic"], rungs&.index(problem["elo"]), rungs&.size) ||
      fact_grade(problem["text"])
  end

  def source_grade(source)
    grade = source.to_h["grade"]
    grade.to_i if grade.present? && grade.to_i.between?(1, 12)
  end

  def family_grade(family, topic_name, rung = nil, rung_count = nil)
    return if family.blank?

    value = map[family]
    case value
    when Integer then value
    when Array
      index = rung && rung_count.to_i > 1 ? (rung * value.size / rung_count) : 0
      value[[ index, value.size - 1 ].min]
    else topic_first_grade(topic_name)
    end
  end

  def topic_first_grade(topic_name)
    Curriculum::TOPICS.sort.find { |_, names| names.include?(topic_name) }&.first
  end

  # Within 100 without carrying or borrowing is first grade; with it, and the
  # times tables and their division, second.
  def fact_grade(text)
    match = FACT.match(text.to_s) or return
    a, op, b = match[1].to_i, match[2], match[3].to_i

    case op
    when "+" then a + b <= 100 && (a % 10) + (b % 10) < 10 ? 1 : 2
    when "−", "-" then (a % 10) >= (b % 10) ? 1 : 2
    else 2
    end
  end

  # Family → sorted distinct ratings, from a file's rows.
  def rungs_by_family(problems)
    problems.select { |problem| problem["family"].present? }.group_by { |problem| problem["family"] }.
      transform_values { |rows| rows.map { |row| row["elo"] }.uniq.sort }
  end
end
