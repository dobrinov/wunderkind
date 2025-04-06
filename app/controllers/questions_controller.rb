class QuestionsController < ApplicationController
  def show
    @assignment = Assignment.find params[:assignment_id]
    questions = @assignment.questions
    @question = questions.find params[:id]
    @user_answer = @question.user_answers.where(assignment: @assignment).first
    @total_questions_count = questions.size
    @answered_questions_count = @assignment.user_answers.count
  end
end
