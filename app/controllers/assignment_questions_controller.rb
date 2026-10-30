class AssignmentQuestionsController < AuthenticatedController
  layout "modal"

  def show
    @assignment_question = AssignmentQuestion.joins(:assignment).where(assignments: { user: current_user }).find params[:id]
    @assignment = @assignment_question.assignment
    @question = @assignment_question.question
    @answer = @assignment_question.user_answer
    @next_assignment_question = @assignment.next_assignment_question

    # A mock exam whose time is up is over, whatever was left: to its result.
    if @assignment.mock? && (@assignment.completed_at? || MockExam.over?(@assignment))
      MockExam.finish!(@assignment)
      return redirect_to assignment_summary_path(@assignment) if @answer.nil? || @assignment.completed_at?
    end

    @numeric_answer = @question.exact_value? && ExactValue.parse(@question.grading["expected"]).present?
    @hint = @question.hint if @answer.nil? && @assignment.hints_allowed? && @question.hint&.reviewed?
  end
end
