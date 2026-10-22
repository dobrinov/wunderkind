# A preparation session for one competition or exam — see CompetitionPractice.
# Open to any student, entered or not: wanting to see what the Kangaroo is like
# before saying you will sit it is a fine reason to practise for it.
class CompetitionPracticesController < CompetitionsController
  def create
    assignment = CompetitionPractice.execute(user: current_user, event: event)
    track :session_started, kind: assignment.kind
    redirect_to question_path(assignment.next_assignment_question)
  rescue CompetitionPractice::NothingToPractise
    redirect_back_or_to competitions_path, alert: t("competitions.nothing_to_practise")
  end
end
