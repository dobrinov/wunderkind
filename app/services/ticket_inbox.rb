# The admin inbox („Входящи") as a query: every ticket — a report or a
# suggestion — filtered by where it stands and by kind, and optionally to one
# question. The inbox list, the ticket page's previous/next and its „3 от 11"
# all read the same object, so stepping through tickets walks exactly the list
# the admin was looking at.
#
# Three states split the tickets between them: waiting on us (new, or the
# other side wrote last), in conversation (we wrote last and wait for an
# answer), closed. Two more are kept for links made before the inbox:
# `active` (the first two together — the questions list's „⚑ 3" link) and
# `all`.
class TicketInbox
  FILTERS = %w[waiting talking closed].freeze
  LEGACY_FILTERS = %w[active all].freeze
  KINDS = %w[all report suggestion].freeze
  PER_PAGE = 50

  attr_reader :filter, :kind, :question

  def initialize(filter: nil, kind: nil, question_id: nil)
    @filter = (FILTERS + LEGACY_FILTERS).include?(filter) ? filter : FILTERS.first
    @kind = KINDS.include?(kind) ? kind : KINDS.first
    @question = Question.find_by(id: question_id) if question_id.present?
  end

  # The parameters that reproduce this view, for links that keep it.
  def params
    { filter: filter, kind: (kind unless kind == "all"), question_id: question&.id }.compact
  end

  def tickets
    by_kind(by_question(state_scope(filter))).order(updated_at: :desc, id: :desc)
  end

  # Counts on the state tabs, within the kind chosen; „Затворени" carries
  # none — a growing archive is not work.
  def state_counts
    { "waiting" => by_kind(by_question(QuestionReport.awaiting_team)).count,
      "talking" => by_kind(by_question(QuestionReport.awaiting_reply)).count }
  end

  # Counts on the kind chips, within the state chosen. One query.
  def kind_counts
    counts = by_question(state_scope(filter)).group(:kind).count
    { "report" => counts["report"].to_i, "suggestion" => counts["suggestion"].to_i }.
      then { |by_kind| by_kind.merge("all" => by_kind.values.sum) }
  end

  # Where a ticket sits in this list: its position (1-based) and its
  # neighbours, or nil when the ticket is not in it (opened from elsewhere).
  # The list is plucked as ids — a few thousand integers at worst.
  def position_of(ticket)
    ids = tickets.pluck(:id)
    index = ids.index(ticket.id)
    return unless index

    { index: index + 1, total: ids.size,
      previous: (ids[index - 1] if index.positive?), next: ids[index + 1] }
  end

  private

  def state_scope(name)
    case name
    when "waiting" then QuestionReport.awaiting_team
    when "talking" then QuestionReport.awaiting_reply
    when "closed" then QuestionReport.closed
    when "active" then QuestionReport.active
    else QuestionReport.all
    end
  end

  def by_kind(scope)
    kind == "all" ? scope : scope.where(kind: kind)
  end

  def by_question(scope)
    question ? scope.where(question: question) : scope
  end
end
