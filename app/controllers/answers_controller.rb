class AnswersController < AuthenticatedController
  layout "modal"

  def show
    @assignment_question = AssignmentQuestion.joins(:assignment).where(assignments: { user: current_user }).find params[:question_id]
    @answer = @assignment_question.user_answer
    @assignment = @assignment_question.assignment
    @question = @assignment_question.question
  end

  def create
    assignment_question =
      AssignmentQuestion.
        joins(:assignment).
        where(assignments: { user: current_user }).
        find params[:question_id]

    assignment = assignment_question.assignment

    outcome = AnswerSubmission.call(
      assignment_question: assignment_question,
      user: current_user,
      raw: answer_params,
      duration_ms: duration_ms
    )

    flash[:xp_earned] = outcome.xp_earned
    flash[:new_badges] = outcome.new_badges.map(&:key) if outcome.new_badges.any?

    next_assignment_question = assignment.next_assignment_question
    feedback_after_answer =
      if assignment.feedback_after_answer.nil?
        current_user.feedback_after_answer
      else
        assignment.feedback_after_answer
      end

    if next_assignment_question && feedback_after_answer
      redirect_to question_path(assignment_question)
    elsif next_assignment_question
      redirect_to question_path(next_assignment_question)
    else
      redirect_to assignment_summary_path(assignment)
    end
  end

  private

  def answer_params
    params.permit(:value, :state, selected_ids: [])
  end

  def duration_ms
    started_at = Time.zone.parse(params[:started_at].to_s)
    return nil if started_at.nil?

    ((Time.current - started_at) * 1000).round.clamp(0, 30.minutes.in_milliseconds)
  rescue ArgumentError
    nil
  end
end
