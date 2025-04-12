class QuestionsController < AuthenticatedController
  layout "modal"

  def show
    @assignment = Assignment.find params[:assignment_id]
    @question = @assignment.questions.find params[:id]
  end
end
