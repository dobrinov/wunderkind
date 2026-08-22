# Reporting a broken problem from inside a duel. Same rows and same queue as the
# practice flow (see QuestionReport); what differs is how the problem is named —
# a challenge_question of a match this student played, not an assignment of
# their own.
#
# A duel has no hints and no "не съм го учил" because both would be worth points
# to whoever used them fastest. A report is not in that class: it awards nothing,
# skips nothing and stops no clock, so filing one costs the reporter their own
# seconds and no one else's.
class ChallengeReportsController < AuthenticatedController
  def create
    challenge = find_challenge
    challenge_question = challenge.challenge_questions.find params[:challenge_question_id]
    reason = params[:reason].to_s

    if QuestionReport.reasons.key?(reason)
      QuestionReport.file!(
        question: challenge_question.question,
        user: current_user,
        reason: reason,
        note: params[:note]
      )
      redirect_back_to_match challenge, notice: t("reports.thanks")
    else
      redirect_back_to_match challenge, alert: t("reports.no_reason")
    end
  end

  private

  def find_challenge
    Challenge.
      where(id: ChallengeParticipant.where(user_id: current_user.id).select(:challenge_id)).
      find params[:challenge_id]
  end

  # Back to the match — mid-play that is the problem still on the clock (serving
  # it again does not re-stamp question_started_at, so the report buys no
  # thinking time), after the final whistle it is the result screen.
  def redirect_back_to_match(challenge, **flash_message)
    redirect_to helpers.internal_path(params[:return_to], challenge_path(challenge)), **flash_message
  end
end
