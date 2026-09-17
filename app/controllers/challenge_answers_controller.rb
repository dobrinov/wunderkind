class ChallengeAnswersController < AuthenticatedController
  def create
    challenge = find_challenge
    participant = challenge.participant_for(current_user)
    challenge_question = challenge.challenge_questions.find params[:challenge_question_id]

    verdict = submit(participant, challenge_question)
    path = challenge_path(challenge, close_path: challenges_path)

    # The same two answers as the practice flow, and for the same reason: the
    # cue has to ring on this page, before the next problem replaces it. See
    # AnswersController#advance_to.
    respond_to do |format|
      format.html { redirect_to path }
      format.json { render json: { verdict: verdict, redirect: path } }
    end
  end

  private

  # A toast, not a feedback screen: in a race, stopping the leader to explain
  # their answer would hand the match to whoever reads slower. The
  # question-by-question breakdown is on the result screen. Returns the verdict
  # for the cue, or nil where there is nothing to sound.
  def submit(participant, challenge_question)
    outcome = ChallengeSubmission.call(
      participant: participant,
      challenge_question: challenge_question,
      raw: answer_params
    )

    if outcome.result.correct
      flash[:notice] = t("challenges.answer_correct", points: outcome.points)
      "correct"
    else
      flash[:alert] = t("challenges.answer_wrong")
      "wrong"
    end
  rescue ChallengeSubmission::BlankResponse
    flash[:alert] = t("answers.blank")
    nil
  rescue ChallengeSubmission::AlreadyAnswered, ChallengeSubmission::OutOfTime
    # The match moved on without this submission — a double-click, a stale tab,
    # a clock that ran out mid-answer. The redirect shows whatever state the
    # match is actually in now.
    nil
  end

  def find_challenge
    Challenge.
      where(id: ChallengeParticipant.where(user_id: current_user.id).select(:challenge_id)).
      find params[:challenge_id]
  end

  def answer_params
    params.permit(:value, :state, selected_ids: [])
  end
end
