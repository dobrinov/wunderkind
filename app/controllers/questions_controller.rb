class QuestionsController < AuthenticatedController
  layout "modal"

  def show
    @assignment = Assignment.find params[:assignment_id]
    @question = @assignment.questions.find params[:id]

    @numeric_answer =
      if @question.possible_answers.any?
        false
      else
        @question.answer.match?(/\A[+-]?\d+\z/)
      end
  end
end
