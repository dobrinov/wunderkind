# Making a friend, and the two lists a student sees.
#
# Thin on purpose: a friendship is two columns and a status, and the only
# thing here that is not a query is `request!`, which exists because „type a
# code" has four different wrong answers and a controller should not be the
# place that knows them apart.
module Friends
  Result = Struct.new(:friendship, :error, keyword_init: true) do
    def ok? = error.nil?
  end

  module_function

  # Asking to be somebody's friend, by the code they gave you.
  #
  # Already-friends and already-asked are not errors in any useful sense — the
  # student typed a code and the answer is „you two are sorted" — but they are
  # different sentences, and a child typing a code that belongs to nobody needs
  # to know it was the code and not them.
  def request!(user, code)
    other = User.student.find_by(friend_code: code.to_s.strip.upcase.presence)

    return Result.new(error: :unknown_code) if other.nil?
    return Result.new(error: :yourself) if other.id == user.id

    existing = Friendship.pick_between(user, other)
    return Result.new(friendship: existing, error: existing.accepted? ? :already_friends : :already_asked) if existing

    Result.new(friendship: Friendship.create!(requester: user, addressee: other))
  end

  # Friends, those online first and then by name: the list is read to decide
  # who to invite, and somebody who is not there is not an answer to that.
  def list(user)
    user.friends.
      order(Arel.sql("(last_seen_at > '#{User::ONLINE_WINDOW.ago.to_fs(:db)}') DESC NULLS LAST"), :name).
      to_a
  end

  def pending_for(user)
    Friendship.awaiting(user).includes(:requester).order(created_at: :desc).to_a
  end

  def accept!(user, friendship)
    return false unless friendship.addressee_id == user.id && friendship.pending?

    friendship.accept!
  end

  # Used for both „no thanks" and „not any more", which are the same row and
  # the same button to everybody but a database.
  def remove!(user, friendship)
    return false unless [ friendship.requester_id, friendship.addressee_id ].include?(user.id)

    friendship.destroy
  end
end
