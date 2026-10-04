# „Да видим откъде да започнем" — the eight questions that place a new student,
# and the screen that tells them where they landed.
#
# A session rather than a wizard of its own: it is an ordinary Assignment of
# `kind: :placement`, so the practice screen, the answer form, the sounds and
# the report control all work unchanged. The only thing placement adds to that
# flow is choosing each next question from the answers so far — see Placement.
class PlacementsController < AuthenticatedController
  before_action :require_student

  # The welcome screen. Sign-up lands here, which is also why this route has to
  # exist at all: a redirect from sign-up is a GET, and `create` is not.
  def new
    return redirect_to calendar_path unless Placement.due?(current_user)

    render layout: "modal"
  end

  def create
    return redirect_to calendar_path unless Placement.due?(current_user)

    # Resuming is not a new session, and must not be counted as one.
    assignment = Placement.unfinished(current_user)
    if assignment.nil?
      assignment = Placement.start!(current_user)
      track :session_started, kind: assignment.kind
    end

    redirect_to question_path(assignment.next_assignment_question)
  rescue Placement::NotEnoughQuestions, Dispatcher::NotEnoughQuestions
    redirect_to calendar_path, alert: t("assignments.not_enough_questions")
  end

  # The result. Read off the finished assignment rather than from the flash, so
  # a child can come back to it and a parent can be shown it.
  def show
    @assignment = current_user.assignments.placement.find(params[:id])
    @result = Placement.result(@assignment)

    render layout: "modal"
  end

  private

  def require_student
    redirect_to home_path_for(current_user) unless current_user.student?
  end
end
