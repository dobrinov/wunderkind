class AssignmentsController < AuthenticatedController
  def index
    @assignments = Assignment.where(user: current_user).order(created_at: :desc)
    @date = params[:date].to_date if params[:date].present?

    if @date.present?
      @assignments = @assignments.where(created_at: @date.all_day)
    end
  end

  def create
    assignment = Assignment.create! user: current_user
    assignment.questions << Question.order("RANDOM()").take(10)

    redirect_to assignment_path(assignment)
  end

  def show
    @assignment = Assignment.find(params[:id])

    redirect_to assignment_question_path(@assignment, @assignment.next_question) unless @assignment.completed_at?
  end
end
