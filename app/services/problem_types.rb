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

  def offered
    counts = self.counts
    all.select { |type| counts[type.slug].to_i >= MIN_PUBLISHED }.map { |type| [ type, counts[type.slug] ] }
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
    picked = Dispatcher.pick(user, count: question_count, topic_ids: topic_ids, problem_type: type.slug)
    raise NothingToPractise if picked.empty?

    assignment = Assignment.build(user: user, kind: :practice)
    picked.sort_by(&:elo).each_with_index do |question, index|
      assignment.assignment_questions.build(question: question, position: index + 1)
    end
    assignment.save!
    assignment
  end
end
