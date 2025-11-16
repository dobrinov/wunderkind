class AssignmentsController < AuthenticatedController
  def index
    @assignments = Assignment.where(user: current_user).order(created_at: :desc)
    @date = params[:date].to_date
    @assignments = @assignments.where(created_at: @date.all_day)
  end

  def create
    assignment = AssignmentCreator.execute(user: current_user, question_count: 10)
    redirect_to question_path(assignment.next_assignment_question)
  end

  def summary
    @assignment = Assignment.find params[:id]

    redirect_to question_path(@assignment.next_assignment_question) unless @assignment.completed_at?

    render layout: "modal"
  end

  def show
    @assignment = Assignment.find params[:id]

    render layout: "modal"
  end
end
