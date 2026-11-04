# A preparation session for one competition or exam — see CompetitionPractice.
# Open to any student, entered or not: wanting to see what the Kangaroo is like
# before saying you will sit it is a fine reason to practise for it.
#
# Where the bank holds too few of the event's problems near the child, a press
# is not wasted on an error: they are told so and given today's ordinary
# session, which is the practice they can actually have.
class CompetitionPracticesController < CompetitionsController
  def create
    session.delete(:signup_competition) if session[:signup_competition] == event.slug
    assignment = CompetitionPractice.unfinished(current_user, event)
    unless assignment
      assignment = CompetitionPractice.execute(user: current_user, event: event)
      track :session_started, kind: assignment.kind
    end
    redirect_to question_path(assignment.next_assignment_question)
  rescue CompetitionPractice::NothingToPractise
    practise_as_usual
  end

  private

  def practise_as_usual
    resumed = DailyPractice.unfinished_today(current_user)
    assignment = resumed || DailyPractice.compose(current_user)
    track :session_started, kind: assignment.kind unless resumed
    redirect_to question_path(assignment.next_assignment_question),
                notice: t("competitions.practising_as_usual", name: event.short.presence || event.name.to_s)
  rescue Dispatcher::NotEnoughQuestions
    redirect_back_or_to competitions_path, alert: t("competitions.nothing_to_practise")
  end
end
