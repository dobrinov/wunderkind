# What counts as „the same problem again" inside one session.
#
# The text alone cannot say. The ladder families reword their variants on
# purpose — „Борис е по-нисък от Тодор…“ and „Ива е по-висока от Мария…“ are
# one family, as are the squares of stickers, stamps and cards — so a cap on
# the text's shape (ProblemSeeds.shape_of) let a struggling child meet „кой е
# най-висок“ three times in twelve problems, which reads as the app being
# stuck. So the key is, in order:
#   * the family the problem was written in (questions.family), one per session;
#   * the past-paper task it is, or was written on the model of — the easy,
#     medium and hard of one task are one idea — one per session;
#   * otherwise the shape, SessionComposer::MAX_PER_SHAPE per session, which
#     is what keeps the arithmetic fact tables from filling a young session.
module Templates
  module_function

  def key(question)
    return "family:#{question.family}" if question.family.present?

    source = question.source.to_h
    return "task:#{task_of(source)}" if source["competition"].present? && source["number"].present?

    "shape:#{ProblemSeeds.shape_of(question.body_text.to_s)}"
  end

  def cap(key) = key.start_with?("shape:") ? SessionComposer::MAX_PER_SHAPE : 1

  # The questions in order, each kept only while its template has room.
  def capped(questions, seen = Hash.new(0))
    questions.select do |question|
      template = key(question)
      next false if seen[template] >= cap(template)

      seen[template] += 1
    end
  end

  # `scope` without the templates named in `keys`, so a query can look past
  # the ones a session has already filled.
  def excluding(scope, keys)
    groups = keys.group_by { |template| template.split(":", 2).first }
    families = Array(groups["family"]).map { |template| template.delete_prefix("family:") }
    tasks = Array(groups["task"]).map { |template| template.delete_prefix("task:") }
    shapes = Array(groups["shape"]).map { |template| template.delete_prefix("shape:") }

    scope = scope.where("questions.family IS NULL OR questions.family NOT IN (:families)", families: families) if families.any?
    scope = scope.where.not("#{TASK_SQL} IN (:tasks)", tasks: tasks) if tasks.any?
    # A named bind, not "?": the regex literals in SHAPE_SQL contain "?".
    scope = scope.where.not("#{SessionComposer::SHAPE_SQL} IN (:shapes)", shapes: shapes) if shapes.any?
    scope
  end

  TASK_SQL = "concat_ws(':', questions.source ->> 'competition', questions.source ->> 'year', questions.source ->> 'number')".freeze

  def task_of(source) = [ source["competition"], source["year"], source["number"] ].join(":")
end
