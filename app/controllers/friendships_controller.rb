# Friends: who they are, who is here, and inviting one to a duel.
#
# Students only. A parent has no use for this and a child's friends are not a
# parent's to browse — the parent's window into their child is
# /parents/children/:id, which is about practice rather than about who they
# know.
class FriendshipsController < AuthenticatedController
  before_action :require_student

  def index
    @friends = Friends.list(current_user)
    @pending = Friends.pending_for(current_user)
    @code = current_user.ensure_friend_code!
    # So a friend already invited shows as invited rather than as a button that
    # opens a second room.
    @invited_ids = ChallengeMatchmaker.invites_sent_by(current_user).map(&:invited_user_id)
  end

  def create
    result = Friends.request!(current_user, params[:code])

    if result.ok?
      redirect_to friends_path, notice: t("friends.requested", name: helpers.opponent_name(result.friendship.addressee))
    else
      redirect_to friends_path, alert: t("friends.errors.#{result.error}")
    end
  end

  def accept
    Friends.accept!(current_user, friendship)

    redirect_to friends_path
  end

  def destroy
    Friends.remove!(current_user, friendship)

    redirect_to friends_path
  end

  # „Хайде на двубой" — opens a room only this friend can take a seat in.
  def duel
    friend = friendship.other_than(current_user)
    return redirect_to friends_path, alert: t("friends.errors.not_yet") unless friendship.accepted?

    challenge = ChallengeMatchmaker.invite!(user: current_user, friend: friend)
    return redirect_to friends_path, alert: t("friends.errors.busy") if challenge.nil?

    track :duel_started, matched: "waiting"
    redirect_to challenge_path(challenge, close_path: friends_path)
  rescue Dispatcher::NotEnoughQuestions
    redirect_to friends_path, alert: t("challenges.not_enough_questions")
  end

  private

  # Only ever a friendship this student is actually in — the id in the URL is
  # not trusted to be theirs.
  def friendship
    @friendship ||= Friendship.involving(current_user).find(params[:id])
  end

  def require_student
    redirect_to home_path_for(current_user) unless current_user.student?
  end
end
