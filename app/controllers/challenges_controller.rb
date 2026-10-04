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

    # Whether there was already somebody waiting is the whole question about
    # duels: a queue nobody is ever in is a feature that does not work, and it
    # looks identical in the logs to one that does.
    track :duel_started, matched: challenge.waiting? ? "waiting" : "now"
    redirect_to challenge_path(challenge, close_path: challenges_path)
  rescue Dispatcher::NotEnoughQuestions
    redirect_to challenges_path, alert: t("challenges.not_enough_questions")
  end

  def show
    @challenge = rematched(settled_challenge)
    return redirect_to challenge_path(@challenge) if @challenge.id != params[:id].to_i

    @participant = @challenge.participant_for(current_user)
    @opponent = @challenge.opponent_for(current_user)

    if @challenge.active?
      @challenge_question = @participant.next_challenge_question

      if @challenge_question
        # Serving stamps the player's clock, so an admin looking in through
        # ImpersonationsController must not: the student is not at the screen,
        # and the seconds being spent are the ones their speed bonus is scored
        # out of. The read-only rule in ApplicationController is on the verb
        # and cannot see this, which is why the guard is here at the write.
        ChallengeSubmission.serve(@participant) unless impersonating?
        @question = @challenge_question.question
        @numeric_answer = @question.exact_value? && ExactValue.parse(@question.grading["expected"]).present?
      end
    end

    render layout: "modal"
  end

  # Polled by the match screen: the live scoreboard, the clock, and the status
  # the client compares against its own to know when to reload.
  def state
    challenge = rematched(settled_challenge)
    participant = challenge.participant_for(current_user)
    opponent = challenge.opponent_for(current_user)

    render json: {
      status: challenge.status,
      # Set only when the poll moved this player into a different room: they
      # were waiting in a lobby of their own and have just been paired into
      # somebody else's, so the page they are on is no longer their match.
      redirect: (challenge_path(challenge) if challenge.id != params[:id].to_i),
      # nil until both players have readied; a number while the room counts
      # down. The client renders it and asks again when it reaches zero, which
      # is what turns the countdown into a match.
      starts_in: challenge.seconds_to_start,
      # What the speed meter is measured against. Sent rather than hard-coded
      # in the markup so a match played under a different per-problem budget
      # still draws a meter that means what it says.
      question_seconds: challenge.seconds_per_question,
      speed_points: ChallengeScoring::SPEED_POINTS,
      # Only ever read by the client at the moment the status changes under it:
      # the match screen counts the result once, there, because a duel can end
      # on the clock with nobody making a request that would notice. nil while
      # the match is still on.
      result: challenge.finished? ? result_for(challenge, participant) : nil,
      seconds_left: challenge.seconds_left,
      you: {
        score: participant.score,
        answered: participant.answered_count,
        ready: participant.ready?,
        # Seconds this player has been looking at the problem in front of them,
        # measured from the server's own stamp. The speed meter is drawn from
        # it rather than from when the browser happened to paint, for the same
        # reason the bonus itself is: a reload must not buy thinking time.
        elapsed: participant.seconds_on_current_question.round(2)
      },
      opponent: opponent && {
        name: helpers.opponent_name(opponent.user),
        score: opponent.score,
        answered: opponent.answered_count,
        done: opponent.done?,
        ready: opponent.ready?
      }
    }
  end

  # „Готов съм". Both players press it and the last press starts the countdown
  # — there is no host and no start button; see ChallengeLobby for why.
  def ready
    challenge = find_challenge
    ChallengeLobby.ready!(challenge, challenge.participant_for(current_user))

    redirect_to challenge_path(challenge)
  end

  # Backing out before the clock starts — an empty lobby, or a full one still
  # waiting on a „Готов съм". A match already under way cannot be abandoned:
  # walking away from a duel you are losing has to cost the loss.
  def destroy
    challenge = find_challenge
    challenge.update!(status: :abandoned) if challenge.waiting? || challenge.lobby?

    redirect_to challenges_path
  end

  private

  def result_for(challenge, participant)
    return "draw" if challenge.draw?

    challenge.winner_id == participant.user_id ? "win" : "loss"
  end

  def require_student
    redirect_to home_path_for(current_user) unless current_user.student?
  end

  def find_challenge
    Challenge.
      where(id: ChallengeParticipant.where(user_id: current_user.id).select(:challenge_id)).
      find params[:id]
  end

  # Every read of a live match is also the chance to move it on: a room nobody
  # turned up to, a countdown that has run out, a clock that has. There is no
  # job, and a match can expire with neither player making a request — so
  # opening a duel screen is a GET that starts matches, pays bonuses and awards
  # badges. Not on behalf of somebody being looked at through impersonation;
  # the next request either player makes will do it.
  def settled_challenge
    challenge = find_challenge
    return challenge if impersonating?

    if challenge.stale?
      challenge.update!(status: :abandoned)
    else
      # Two independent steps, and neither may swallow the other: a `||` here
      # meant a read that started a match could not also be the read that
      # finished one. ChallengeLobby.begin! now refuses to start a match whose
      # clock has already gone, so the two cannot both fire today — but that is
      # a property of begin!, not something this line should be relying on.
      challenge.reload if ChallengeLobby.begin!(challenge)
      challenge.reload if ChallengeSubmission.settle(challenge)
    end

    challenge
  end

  # A player sitting in a lobby of their own is still looking, and their poll is
  # the only thing that happens while they look. Without this, two people who
  # pressed the button a second apart would each sit in an empty room until one
  # of them gave up — see ChallengeMatchmaker#call.
  def rematched(challenge)
    return challenge unless challenge.waiting? && !impersonating?

    ChallengeMatchmaker.call(user: current_user)
  rescue Dispatcher::NotEnoughQuestions
    challenge
  end
end
