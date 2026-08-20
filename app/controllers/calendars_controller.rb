class CalendarsController < AuthenticatedController
  layout "application"

  def show
    @calendar = Calendar.new current_user
    @pending_homework = current_user.assignments.
      homework.
      where(completed_at: nil).
      joins(:homework).
      includes(:homework, assignment_questions: :user_answer).
      order("homeworks.due_at")
  end
end
