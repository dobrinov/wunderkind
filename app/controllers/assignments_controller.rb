class AssignmentsController < AuthenticatedController
  def index
    @assignments = Assignment.where(user: current_user).order(created_at: :desc)
    # The in-app links always carry a date, but the bare route and hand-typed
    # URLs reach here too — a missing or garbled date means today, not a 500.
    @date = begin
      Date.iso8601(params[:date].to_s)
    rescue Date::Error
      Time.zone.today
    end
    @assignments = @assignments.where(created_at: @date.all_day)
  end

  def create
    assignment = SessionComposer.execute(user: current_user, question_count: 10)
    redirect_to question_path(assignment.next_assignment_question)
  rescue Dispatcher::NotEnoughQuestions
    redirect_to calendar_path, alert: t("assignments.not_enough_questions")
  end

  def create_daily
    assignment = DailyPractice.execute(user: current_user)
    redirect_to question_path(assignment.next_assignment_question)
  rescue Dispatcher::NotEnoughQuestions
    redirect_to calendar_path, alert: t("assignments.not_enough_questions")
  end

  def summary
    @assignment = current_user.assignments.find params[:id]

    redirect_to question_path(@assignment.next_assignment_question) unless @assignment.completed_at?

    render layout: "modal"
  end

  def show
    @assignment = current_user.assignments.find params[:id]

    render layout: "modal"
  end
end
