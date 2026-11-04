# „Типови задачи": problems grouped by the idea a child needs rather than by
# topic — „Възрастови задачи", „Везни и равновесие", „Работа назад от края".
# A Bulgarian teacher and every competition book think in these, and a child
# preparing for a competition wants „ten more like that one".
#
# The list is config/problem_types.yml, written by a person (slug, name, the
# short line a child reads, an example); a question carries one slug in
# `questions.problem_type`, set by its problem file — a past paper's problem
# by its own `type:`, ours written on its model inheriting it (PastPapers).
# A type is offered once the bank has MIN_PUBLISHED published problems of it.
#
# Practising a type (`execute`) is ten problems of it at the student's level,
# easiest first — the order matters more here than in a topic session, since
# the point is to meet one idea and climb with it. Measured like any practice.
module ProblemTypes
  FILE = Rails.root.join("config/problem_types.yml")
  QUESTION_COUNT = 10
  MIN_PUBLISHED = 3

  Type = Struct.new(:slug, :name, :short, :description, :example, keyword_init: true)

  NothingToPractise = Class.new(StandardError)

  module_function

  def all
    @all = nil if Rails.env.development?
    @all ||= YAML.safe_load_file(FILE).map { |row| Type.new(**row.transform_keys(&:to_sym)) }.freeze
  end

  def find(slug) = all.find { |type| type.slug == slug.to_s }

  # Published problems per type, for the ones worth offering.
  def counts
    Question.published.where.not(problem_type: nil).group(:problem_type).count
  end

  # The types worth offering, nearest the student's level first: a list of
  # sixty, from „Кой знак липсва" to „Нормален вид на многочлен", would
  # otherwise open a seven-year-old's page on algebra. A type's level is the
  # median Elo of its published problems.
  def offered(user = nil)
    counts = self.counts
    types = all.select { |type| counts[type.slug].to_i >= MIN_PUBLISHED }
    if user
      target = Dispatcher.target_rating(user.elo)
      levels = medians
      types = types.sort_by.with_index { |type, index| [ (levels[type.slug].to_f - target).abs, index ] }
    end
    types.map { |type| [ type, counts[type.slug] ] }
  end

  def medians
    Question.published.where.not(problem_type: nil).group(:problem_type)
            .pluck(:problem_type, Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY questions.elo)")).to_h
  end

  # Where the type was set: the real past-paper problems of it, newest first.
  def given_at(type, limit: nil)
    scope = Question.published.where(problem_type: type.slug).where("questions.source ->> 'kind' = 'original'")
                    .order(Arel.sql("(questions.source ->> 'year')::int DESC"))
    scope = scope.limit(limit) if limit
    scope.to_a
  end

  def execute(user:, type:, question_count: QUESTION_COUNT)
    pool = Question.published.where(problem_type: type.slug)
    topic_ids = Topic.joins(:questions).merge(pool).distinct.pluck(:id)
    # At the child's level where the type reaches it; where it does not, the
    # hardest of it rather than a random spread. Widening without a bound
    # handed a 2400 student the type's 1100 problems, and „easiest first"
    # then opened the session on them.
    # Past the grade hold: a type opened by name is the idea the child asked
    # for, at whatever grade the papers set it.
    picked = Dispatcher.pick(user, count: question_count, topic_ids: topic_ids, problem_type: type.slug,
                                   reach: SessionComposer::REACH, beyond_grade: true)
    if picked.size < question_count
      target = Dispatcher.target_rating(Dispatcher.rating_for(user, topic_ids))
      picked += Dispatcher.available_pool(user, allow: topic_ids, beyond_grade: true).where(problem_type: type.slug)
                          .where.not(id: picked.map(&:id))
                          .order(Arel.sql("ABS(questions.elo - #{target.to_i}), RANDOM()"))
                          .limit(question_count - picked.size).to_a
    end
    raise NothingToPractise if picked.empty?

    assignment = Assignment.build(user: user, kind: :practice)
    picked.sort_by(&:elo).each_with_index do |question, index|
      assignment.assignment_questions.build(question: question, position: index + 1)
    end
    assignment.save!
    assignment
  end
end
