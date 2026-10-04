# Two students who agreed to be friends.
#
# One row per pair, holding whichever way round it was asked — so every query
# has to look in both columns, which is what `for` and `between` are for. The
# alternative, a mirrored pair of rows, makes „are we friends" a cheap read and
# every write a chance to leave half a friendship behind.
#
# **How you find somebody is the whole design.** This app is used by children,
# so there is no search by name and no browsing of other people: the only way
# to befriend somebody is to type a code they handed you, the same stance the
# app already takes for linking a parent to a child. A code cannot be guessed
# into a stranger's account — it is six characters out of an alphabet chosen to
# have no lookalikes — and it is only ever seen by somebody the child showed
# their own screen to.
class Friendship < ApplicationRecord
  belongs_to :requester, class_name: "User"
  belongs_to :addressee, class_name: "User"

  enum :status, { pending: 0, accepted: 1 }, default: :pending

  validates :requester_id, uniqueness: { scope: :addressee_id }
  validate :not_yourself
  validate :not_already_the_other_way_round, on: :create

  scope :involving, ->(user) { where(requester_id: user.id).or(where(addressee_id: user.id)) }
  scope :awaiting, ->(user) { pending.where(addressee_id: user.id) }

  # The friendship between these two, whichever way it was asked.
  # The row between these two, whichever way round it was asked, inside
  # whatever scope this is called on.
  def self.pick_between(one, other)
    where(requester_id: one.id, addressee_id: other.id).
      or(where(requester_id: other.id, addressee_id: one.id)).
      first
  end

  def other_than(user)
    requester_id == user.id ? addressee : requester
  end

  def accept!
    update!(status: :accepted, accepted_at: Time.current)
  end

  private

  def not_yourself
    errors.add(:addressee_id, :invalid) if requester_id == addressee_id
  end

  def not_already_the_other_way_round
    return if requester_id.nil? || addressee_id.nil?
    return unless Friendship.where(requester_id: addressee_id, addressee_id: requester_id).exists?

    errors.add(:base, :taken)
  end
end
