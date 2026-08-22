# The student's way out of a broken question, from inside the practice flow.
# Recorded and nothing more: see QuestionReport for why a report touches no
# grading, rating or reward, and why one student can only have one report per
# question.
class QuestionReportsController < AuthenticatedController
  def create
    assignment_question = find_assignment_question
    reason = params[:reason].to_s

    if QuestionReport.reasons.key?(reason)
      QuestionReport.file!(
        question: assignment_question.question,
        user: current_user,
        reason: reason,
        note: params[:note]
      )
      redirect_back_to_question assignment_question, notice: t("reports.thanks")
    else
      redirect_back_to_question assignment_question, alert: t("reports.no_reason")
    end
  end

  private

  def find_assignment_question
    AssignmentQuestion.
      joins(:assignment).
      where(assignments: { user: current_user }).
      find params[:question_id]
  end

  # Back where the report was filed from — the question, its feedback, or the
  # review of a past answer — rather than out of the session.
  def redirect_back_to_question(assignment_question, **flash_message)
    redirect_to helpers.internal_path(params[:return_to], question_path(assignment_question)), **flash_message
  end
end
