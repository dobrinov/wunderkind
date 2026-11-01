# „Пробен изпит" for one exam — see MockExam. Only an exam has one: a
# competition's paper is not a fixed format the app could stand in for.
class MockExamsController < CompetitionsController
  # „Започваме ли?" before the clock: the paper used to open straight on
  # problem 1 with its minutes already running.
  def new
    return redirect_back_or_to competitions_path unless event.exam?

    format = MockExam.format_for(event)
    render "mock_exams/ready", locals: { title: t("mock_exam.start"), subtitle: event.name, count: format.questions,
                                         minutes: format.minutes, running: MockExam.running(current_user, event.slug),
                                         start_path: competition_mock_path(event.slug), params: {} }
  end

  def create
    return redirect_back_or_to competitions_path unless event.exam?

    assignment = MockExam.start!(user: current_user, event: event)
    track :session_started, kind: assignment.kind
    redirect_to question_path(assignment.next_assignment_question)
  rescue MockExam::NothingToSit
    redirect_back_or_to competitions_path, alert: t("competitions.nothing_to_practise")
  end
end
