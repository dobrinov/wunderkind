# Deleting an account from the admin area, and what goes with it.
#
# Most of it is the associations' own `dependent:` — answers, sessions,
# skills, XP, reports, goals — and a parent's managed children nobody else
# is linked to, whose accounts would otherwise be left with no door at all.
# What is done here by hand is what a `dependent:` cannot say, found by
# walking every foreign key onto users:
#
#   * a league the person owns passes to its longest-standing member, as when
#     they leave it themselves (Leagues.leave!), instead of being deleted out
#     from under everybody else in it;
#   * an invitation addressed to them is withdrawn while still open, and a
#     finished match merely forgets who was invited — a NULL invited_user_id on
#     an open room would turn a private invitation into a public lobby;
#   * an unfinished duel they are in is written off (abandoned) for the other
#     player rather than left waiting on somebody who no longer exists;
#   * a question they suggested stays in the bank without the credit.
#
# All of it in one transaction, so it either happens whole or not at all.
class AccountDeletion
  Refusal = Data.define(:reason)

  attr_reader :user

  def initialize(user)
    @user = user
  end

  # Why this account cannot be deleted by this admin, or nil. An admin account
  # is not deleted from here at all (that is a role change first, on purpose),
  # and nobody deletes the account they are signed in with.
  def refusal(by:)
    return :admin if user.admin?
    return :self if user == by

    nil
  end

  # Everybody who disappears with this account: it, and the children whose
  # accounts it holds and no other parent is linked to. A managed child with
  # another parent passes to them instead (User#hand_over_managed_children)
  # and keeps their leagues and duels.
  def accounts = [ user, *managed_children ]

  def managed_children = user.managed_children_lost_on_destroy.order(:name).to_a

  # Linked children who stay: their own login, or held by somebody else.
  def remaining_children = user.children.where.not(id: managed_children.map(&:id)).order(:name).to_a

  def call!
    User.transaction do
      accounts.each { |account| release(account) }
      user.reload.destroy!
    end
  end

  private

  def release(account)
    account.league_memberships.includes(:league).find_each { |membership| Leagues.leave!(account, membership.league) }

    Challenge.where(invited_user: account, status: %i[waiting lobby]).destroy_all
    Challenge.where(invited_user: account).update_all(invited_user_id: nil)

    unfinished = Challenge.joins(:participants).where(challenge_participants: { user_id: account.id })
    unfinished.where(status: %i[waiting lobby]).destroy_all
    Challenge.where(id: unfinished.where(status: :active).select(:id)).update_all(status: Challenge.statuses[:abandoned], finished_at: Time.current)

    Question.where(suggested_by: account).update_all(suggested_by_id: nil)
  end
end
