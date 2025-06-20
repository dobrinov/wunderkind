class AssignmentsController < AuthenticatedController
  def index
    @assignments = Assignment.where(user: current_user).order(created_at: :desc)
    @date = params[:date].to_date if params[:date].present?

    if @date.present?
      @assignments = @assignments.where(created_at: @date.all_day)
    end
  end

  def create
    assignment = Assignment.create! user: current_user, question_count: 10
    next_question = NextQuestion.for(assignment)

    if next_question.blank?
      # TODO: Notify error tracking
      redirect_to calendar_path, alert: "Няма въпроси за задаване"
      return
    end

    assignment.questions << next_question

    redirect_to assignment_question_path(assignment, next_question)
  end

  def completion_summary
    @assignment = Assignment.find(params[:id])

    redirect_to assignment_question_path(@assignment, NextQuestion.for(@assignment)) unless @assignment.completed_at?

    render layout: "modal"
  end

  def show
    @assignment = Assignment.find(params[:id])

    render layout: "modal"
  end
end
