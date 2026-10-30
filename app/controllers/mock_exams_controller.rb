# „Пробен изпит" for one exam — see MockExam. Only an exam has one: a
# competition's paper is not a fixed format the app could stand in for.
class MockExamsController < CompetitionsController
  def create
    return redirect_back_or_to competitions_path unless event.exam?

    assignment = MockExam.start!(user: current_user, event: event)
    track :session_started, kind: assignment.kind
    redirect_to question_path(assignment.next_assignment_question)
  rescue MockExam::NothingToSit
    redirect_back_or_to competitions_path, alert: t("competitions.nothing_to_practise")
  end
end
