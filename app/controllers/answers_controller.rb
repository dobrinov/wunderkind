class AnswersController < AuthenticatedController
  layout "modal"

  def create
    assignment = Assignment.find(params[:assignment_id])

    assignment_question = assignment.assignment_questions.find_by!(question_id: params[:question_id])
    raise "Answer already exists" if assignment_question.user_answer.present?

    answer = assignment_question.create_user_answer!(value: params[:answer], user: current_user)

    next_question = NextQuestion.for(assignment)

    if next_question
      assignment.questions << next_question

      redirect_to assignment_question_path(assignment, next_question)
    else
      assignment.update!(completed_at: Time.current)
      redirect_to completion_summary_assignment_path(assignment)
    end
  end

  def show
    @assignment = Assignment.find(params[:assignment_id])
    @assignment_question = @assignment.assignment_questions.find_by!(question_id: params[:question_id])
    @question = @assignment_question.question
    @is_correct = @assignment_question.user_answer.value == @question.answer
  end
end
