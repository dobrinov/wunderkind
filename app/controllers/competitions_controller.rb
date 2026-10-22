# The competitions inside the app: the ones the student said they will enter,
# counting down, each with a button that builds a session for it — then the
# rest of the season's calendar, to say „ще участвам" to.
#
# The public calendar at /sastezaniya is the same data for a visitor; this is
# the student's own view of it, which is why it is a student page and not a
# parent's (a parent switches into the child's profile, as for practice).
class CompetitionsController < AuthenticatedController
  layout "application"

  before_action :require_student

  def index
    @today = Time.zone.today
    @joined = CompetitionEntry.upcoming_for(current_user, @today)
    @upcoming = Competitions.upcoming(@today) - @joined
  end

  private

  def require_student
    redirect_to home_path_for(current_user) unless current_user.student?
  end

  def event
    @event ||= Competitions.find(params[:competition_slug]) || raise(ActiveRecord::RecordNotFound)
  end
end
