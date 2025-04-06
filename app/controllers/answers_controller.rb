class AnswersController < ApplicationController
  def create
    @assignment = Assignment.find(params[:assignment_id])
    @question = @assignment.questions.find(params[:question_id])
    next_question = @assignment.next_question

    if next_question
      @assignment.update!(completed_at: Time.current)
    end

    answer = @question.user_answers.create!(assignment: @assignment, value: params[:user_answer])
    redirect_to assignment_question_answer_path(@assignment, @question)
  end

  def show
    @assignment = Assignment.find(params[:assignment_id])
    @question = @assignment.questions.find(params[:question_id])
    @answer = @question.user_answers.find_by!(assignment: @assignment)
    @is_correct = @answer.value == @question.answer
    @next_question = @assignment.next_question
  end
end
