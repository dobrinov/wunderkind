# „Типови задачи": every problem type with enough problems, one type's page
# (what it asks, an example, where it was set) and a session of ten of it —
# see ProblemTypes.
class ProblemTypesController < AuthenticatedController
  before_action :require_student
  before_action :set_type, only: [ :show, :create ]

  def index
    @offered = ProblemTypes.offered(current_user)
  end

  def show
    @count = Question.published.where(problem_type: @type.slug).count
    @given_at = ProblemTypes.given_at(@type)
  end

  def create
    assignment = ProblemTypes.execute(user: current_user, type: @type)
    track :session_started, kind: assignment.kind
    redirect_to question_path(assignment.next_assignment_question)
  rescue ProblemTypes::NothingToPractise, Dispatcher::NotEnoughQuestions
    redirect_to problem_type_path(@type.slug), alert: t("problem_types.nothing")
  end

  private

  def set_type
    @type = ProblemTypes.find(params[:slug]) || raise(ActiveRecord::RecordNotFound)
  end

  def require_student
    redirect_to home_path_for(current_user) unless current_user.student?
  end
end
