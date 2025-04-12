class AnswersController < AuthenticatedController
  layout "assignment"

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @question = @assignment.questions.find(params[:question_id])
    answer = @question.user_answers.create!(assignment: @assignment, value: params[:user_answer])

    if @assignment.next_question
      redirect_to assignment_question_path(@assignment, @assignment.next_question)
    else
      @assignment.update!(completed_at: Time.current)
      redirect_to completion_summary_assignment_path(@assignment)
    end
  end

  def show
    @assignment = Assignment.find(params[:assignment_id])
    @question = @assignment.questions.find(params[:question_id])
    @answer = @question.user_answers.find_by!(assignment: @assignment)
    @is_correct = @answer.value == @question.answer
    @next_question = @assignment.next_question
  end
end
