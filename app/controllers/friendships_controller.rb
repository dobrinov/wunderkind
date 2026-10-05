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

  # Setting up a duel with this friend: how long, how many, about what.
  #
  # A screen of its own rather than controls on every row of the list. The
  # friends list is read at a glance to find somebody who is here, and eight
  # copies of the same three pickers is not a glance — and a form per row
  # cannot be nested inside the list's own „Премахни" forms anyway.
  def duel
    return redirect_to friends_path, alert: t("friends.errors.not_yet") unless friendship.accepted?

    @friendship = friendship
    @friend = friendship.other_than(current_user)
    @categories = DuelCategories.for(current_user)
  end

  # Opens a room only this friend can take a seat in.
  def invite
    return redirect_to friends_path, alert: t("friends.errors.not_yet") unless friendship.accepted?

    count, seconds = Challenge.permitted_format(count: params[:question_count], seconds: params[:seconds_per_question])
    challenge = ChallengeMatchmaker.invite!(
      user: current_user,
      friend: friendship.other_than(current_user),
      topic_ids: DuelCategories.selected(current_user, params[:topic_ids]),
      question_count: count,
      seconds_per_question: seconds
    )
    return redirect_to friends_path, alert: t("friends.errors.busy") if challenge.nil?

    track :duel_started, matched: "waiting"
    redirect_to challenge_path(challenge, close_path: friends_path)
  rescue Dispatcher::NotEnoughQuestions
    redirect_to duel_friend_path(friendship), alert: t("challenges.not_enough_questions")
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
