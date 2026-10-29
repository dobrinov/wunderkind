class AssignmentsController < AuthenticatedController
  def index
    StaleSessions.close!(current_user) unless impersonating?
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
    track :session_started, kind: assignment.kind
    redirect_to question_path(assignment.next_assignment_question)
  rescue Dispatcher::NotEnoughQuestions
    redirect_to home_path, alert: t("assignments.not_enough_questions")
  end

  def create_daily
    assignment = DailyPractice.execute(user: current_user)
    track :session_started, kind: assignment.kind
    redirect_to question_path(assignment.next_assignment_question)
  rescue Dispatcher::NotEnoughQuestions
    redirect_to home_path, alert: t("assignments.not_enough_questions")
  end

  def summary
    @assignment = current_user.assignments.find params[:id]

    # A placement ends on a screen of its own, which names where the child
    # starts; this one would only give them a score for a search.
    return redirect_to placement_path(@assignment) if @assignment.placement?
    return redirect_to question_path(@assignment.next_assignment_question) unless @assignment.completed_at?

    @xp_earned = @assignment.xp_earned
    @mistakes_count = MistakePractice.available_count(current_user, from: @assignment)
    # A session of one reported question is a retry from its report thread
    # (MistakePractice.retry): the next step is telling the team whether the
    # fix fixed it, so the way back to the thread leads.
    if @assignment.mistakes? && @assignment.assignment_questions.size == 1
      @retried_report = current_user.question_reports.find_by(question_id: @assignment.assignment_questions.first.question_id)
    end
    render layout: "modal"
  end

  def show
    @assignment = current_user.assignments.find params[:id]

    render layout: "modal"
  end
end
