# How far a parent got through their first run, read off what the tables
# already hold — nothing here is recorded for the purpose. Each step is done
# or not, with the date it happened where a column says so:
#
#   signed_up      — the account's created_at
#   child_added    — their first parent_links row
#   child_in       — a child of theirs has signed in or been switched into at
#                    least once (users.last_login_at; only the *last* time is
#                    kept, so this step carries no date)
#   first_session  — a child of theirs finished a session
#   second_parent  — somebody else is linked to one of their children
#
# The last one is optional; a family with one parent is not stuck.
class FirstSteps
  Step = Data.define(:key, :done, :on)

  KEYS = %i[signed_up child_added child_in first_session second_parent].freeze

  attr_reader :steps

  def initialize(parent, children)
    ids = children.map(&:id)
    first_link = parent.parent_links.minimum(:created_at)
    first_session = ids.any? ? Assignment.finished.where(user_id: ids).minimum(:completed_at) : nil
    second_parent = ids.any? ? ParentLink.where(child_id: ids).where.not(parent_id: parent.id).minimum(:created_at) : nil
    signed_in = children.any? { |child| child.last_login_at.present? }

    @steps = [
      Step.new(key: :signed_up, done: true, on: parent.created_at),
      Step.new(key: :child_added, done: first_link.present?, on: first_link),
      Step.new(key: :child_in, done: signed_in, on: nil),
      Step.new(key: :first_session, done: first_session.present?, on: first_session),
      Step.new(key: :second_parent, done: second_parent.present?, on: second_parent)
    ]
  end

  # Where a parent who has not finished stopped: the first step not done,
  # leaving out the optional last one.
  def stopped_at
    index = steps.first(4).index { |step| !step.done }
    index && index + 1
  end

  def required = steps.first(4)
end
