# The grade ladder — and it exists for exactly one reason, so it is worth being
# blunt about it.
#
# The model has no school grades, on purpose: a first-grader who can do
# third-grade work gets it, and difficulty is the question's Elo, full stop.
# Nothing in here is read by Dispatcher, SessionComposer, Elo, Grading or any
# other part of the answer flow, and nothing here is stored on a user or a
# question. It is presentation only, for the public pages.
#
# But every parent in the country searches in grades — "задачи по математика за
# 3 клас", "НВО 4 клас математика", "упражнения по математика за 2 клас" — and
# a site that refuses to say the word "клас" is a site they never find. So the
# public pages speak grades at the door and the app behind the door still
# speaks Elo. The windows below are editorial, and they overlap on purpose:
# a grade is a range of ability, not a line, which is the same thing the app
# says once a child is inside.
module Curriculum
  Grade = Struct.new(:number, :floor, :ceiling, keyword_init: true) do
    def slug = "#{number}-klas"
    def name = I18n.t("curriculum.grade_name", number: number)
    def range = floor...ceiling

    # The grades with a national external assessment (НВО) at the end of them.
    # Those two pages carry the exam in their title because that is the query.
    def exam? = number.in?(EXAM_GRADES)
  end

  EXAM_GRADES = [ 4, 7 ].freeze

  GRADES = [
    Grade.new(number: 1, floor: 600,  ceiling: 900),
    Grade.new(number: 2, floor: 700,  ceiling: 1000),
    Grade.new(number: 3, floor: 850,  ceiling: 1150),
    Grade.new(number: 4, floor: 1000, ceiling: 1300),
    Grade.new(number: 5, floor: 1150, ceiling: 1450),
    Grade.new(number: 6, floor: 1300, ceiling: 1600),
    Grade.new(number: 7, floor: 1450, ceiling: 1750)
  ].freeze

  # A topic needs this many published questions inside the window before it is
  # worth a line on a grade page: three problems is not a topic a child can
  # practise, and a page listing it would be promising something thin.
  MINIMUM_PER_TOPIC = 25

  # How many worked problems a public page shows. Enough that the page is worth
  # landing on and Google can see it is not a doorway, few enough that the bank
  # is not republished as a free worksheet site.
  SAMPLE_SIZE = 6

  module_function

  def grades = GRADES

  def grade(slug)
    GRADES.find { |candidate| candidate.slug == slug.to_s }
  end

  def find_topic(slug)
    Topic.where.not(parent_id: nil).find_by(slug: slug)
  end

  # Topics worth practising at this grade, commonest first — measured off the
  # bank rather than off a curriculum document, so the page cannot promise a
  # topic that has no problems behind it.
  def topics_for(grade)
    counts = Question.published
                     .where(elo: grade.range)
                     .joins(:topics)
                     .where.not(topics: { parent_id: nil })
                     .group("topics.id")
                     .count

    Topic.where(id: counts.select { |_, count| count >= MINIMUM_PER_TOPIC }.keys)
         .sort_by { |topic| -counts.fetch(topic.id, 0) }
         .map { |topic| [ topic, counts.fetch(topic.id, 0) ] }
  end

  def question_count(grade)
    Question.published.where(elo: grade.range).count
  end

  # The worked examples on a page.
  #
  # Deterministic, not sampled at random: a page that shows different problems
  # on every fetch teaches a crawler it is not worth caching, and a parent who
  # shares a link should land on what they saw.
  #
  # Taken at evenly spaced points across the Elo window rather than off the
  # front of it, because the page claims the problems run from easy to hard —
  # and the first six of a six-thousand-problem range are all the easiest
  # problem in different numbers. One small indexed query per sample, on a page
  # that is cached for half a day.
  #
  # Multiple-choice and exact-value only: an interactive question's answer is a
  # widget state, which has no reading as a line of text and no way to be shown
  # on a page with no widget on it.
  def sample_questions(elo_range:, topic: nil, limit: SAMPLE_SIZE)
    scope = showable(topic)
    floor, ceiling = window(scope, elo_range)
    return [] if floor.nil?

    step = (ceiling - floor).fdiv(limit)

    (0...limit).filter_map { |index| scope.where(elo: (floor + step * index).round..).order(:elo, :id).first }
               .uniq
  end

  def showable(topic)
    scope = Question.published
                    .where(answer_type: [ :multiple_choice, :exact_value ])
                    .where.not(explanation: [ nil, "" ])
                    .includes(:possible_answers, :topics)

    topic ? scope.joins(:topics).where(topics: { id: topic.id }) : scope
  end

  # The span actually occupied inside the asked-for range — a topic that stops
  # at 1360 should not have its samples spread to 1750 and come back with the
  # same problem six times.
  def window(scope, elo_range)
    # Two aggregates rather than one `pick`: `pick` is `limit(1).pluck`, and a
    # LIMIT 1 around MIN/MAX aggregates a single row — it returned [1000, 1000]
    # for a range holding three thousand problems.
    bounded = scope.where(elo: elo_range)
    [ bounded.minimum(:elo), bounded.maximum(:elo) ]
  end

  # The grades a topic is worth showing on, for the cross-links between pages.
  def grades_for(topic)
    published = topic.questions.published
    low, high = published.minimum(:elo), published.maximum(:elo)
    return [] if low.blank?

    GRADES.select { |grade| grade.floor < high && grade.ceiling > low }
  end
end
