# Live duels: two students, the same problems, one clock.
#
# The match screen is driven by polling (see challenge_controller.js) rather
# than a websocket: the app has no ActionCable setup and a duel needs one small
# JSON read a second, which Postgres and Puma will not notice. The server is the
# only authority on the clock, the scores and when the match is over.
class ChallengesController < AuthenticatedController
  before_action :require_student

  def index
    @record = ChallengeRecord.for(current_user)
    @history = ChallengeRecord.history(current_user)
    @current = ChallengeMatchmaker.current(current_user)
  end

  def create
    challenge = ChallengeMatchmaker.call(user: current_user)

    redirect_to challenge_path(challenge, close_path: challenges_path)
  rescue Dispatcher::NotEnoughQuestions
    redirect_to challenges_path, alert: t("challenges.not_enough_questions")
  end

  def show
    @challenge = settled_challenge
    @participant = @challenge.participant_for(current_user)
    @opponent = @challenge.opponent_for(current_user)

    if @challenge.active?
      @challenge_question = @participant.next_challenge_question

      if @challenge_question
        ChallengeSubmission.serve(@participant)
        @question = @challenge_question.question
        @numeric_answer = @question.exact_value? && ExactValue.parse(@question.grading["expected"]).present?
      end
    end

    render layout: "modal"
  end

  # Polled by the match screen: the live scoreboard, the clock, and the status
  # the client compares against its own to know when to reload.
  def state
    challenge = settled_challenge
    participant = challenge.participant_for(current_user)
    opponent = challenge.opponent_for(current_user)

    render json: {
      status: challenge.status,
      seconds_left: challenge.seconds_left,
      you: { score: participant.score, answered: participant.answered_count },
      opponent: opponent && {
        name: helpers.opponent_name(opponent.user),
        score: opponent.score,
        answered: opponent.answered_count,
        done: opponent.done?
      }
    }
  end

  # Backing out of a lobby nobody joined. A match already under way cannot be
  # abandoned: walking away from a duel you are losing has to cost the loss.
  def destroy
    challenge = find_challenge
    challenge.update!(status: :abandoned) if challenge.waiting?

    redirect_to challenges_path
  end

  private

  def require_student
    redirect_to home_path_for(current_user) unless current_user.student?
  end

  def find_challenge
    Challenge.
      where(id: ChallengeParticipant.where(user_id: current_user.id).select(:challenge_id)).
      find params[:id]
  end

  # Every read of a live match is also the chance to resolve one: a lobby nobody
  # joined in time, or a match whose clock has run out. Otherwise a result would
  # wait on the loser coming back to the page, and a lonely lobby would spin
  # until the next player happened to press the button.
  def settled_challenge
    challenge = find_challenge

    if challenge.stale_lobby?
      challenge.update!(status: :abandoned)
    elsif ChallengeSubmission.settle(challenge)
      challenge.reload
    end

    challenge
  end
end
