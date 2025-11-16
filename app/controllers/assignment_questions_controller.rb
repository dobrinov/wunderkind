class AssignmentQuestionsController < AuthenticatedController
  layout "modal"

  def show
    @assignment_question = AssignmentQuestion.joins(:assignment).where(assignments: { user: current_user }).find params[:id]
    @assignment = @assignment_question.assignment
    @question = @assignment_question.question
    @answer = @question.assignment_questions.find_by!(assignment_id: @assignment.id).user_answer
    @next_assignment_question = @assignment.next_assignment_question

    @numeric_answer =
      if @question.possible_answers.any?
        false
      else
        @question.answer.match?(/\A[+-]?\d+\z/)
      end
  end
end
