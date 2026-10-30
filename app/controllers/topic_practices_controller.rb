# „Тренирай тема": the topics on offer, the student's weakest first, and a
# session of the one they pick (TopicPractice).
class TopicPracticesController < AuthenticatedController
  before_action :require_student

  def index
    @offer = TopicPractice.offer(current_user)
    @weakest = TopicPractice.weakest(current_user, offer: @offer)
  end

  def create
    topic = Topic.find(params[:topic_id])
    assignment = TopicPractice.execute(user: current_user, topic: topic)
    track :session_started, kind: assignment.kind
    redirect_to question_path(assignment.next_assignment_question)
  rescue TopicPractice::NothingToPractise, Dispatcher::NotEnoughQuestions
    redirect_to topic_practices_path, alert: t("topic_practice.nothing", topic: topic&.name)
  end

  private

  def require_student
    redirect_to home_path_for(current_user) unless current_user.student?
  end
end
