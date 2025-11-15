# TODO: This one should become an AssignmentQuestionController
class QuestionsController < AuthenticatedController
  layout "modal"

  def show
    @assignment = Assignment.find params[:assignment_id]
    @question = @assignment.questions.find params[:id]
    @answer = @question.assignment_questions.find_by!(assignment_id: @assignment.id).user_answer
    @next_question = @assignment.next_question

    @numeric_answer =
      if @question.possible_answers.any?
        false
      else
        @question.answer.match?(/\A[+-]?\d+\z/)
      end
  end
end
