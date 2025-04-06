class AssignmentsController < AuthenticatedController
  def create
    assignment = Assignment.create! user: current_user
    assignment.questions << Question.order("RANDOM()").take(10)

    redirect_to assignment_path(assignment)
  end

  def show
    @assignment = Assignment.find(params[:id])
    next_question = @assignment.next_question

    if next_question
      next_unanswered = @assignment.next_question
      redirect_to assignment_question_path(@assignment, next_unanswered)
    else
      render :show
    end
  end
end
