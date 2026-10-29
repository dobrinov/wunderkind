# What is waiting on the team, counted once for every place that says so:
# the „Входящи" badge in the admin menu, the badge on „Администрация" in the
# workspace switch, and „Чака нас" on the dashboard. One module so the three
# cannot disagree about what "waiting" means.
module TeamInbox
  module_function

  # Reports whose last word is not the team's (QuestionReport.awaiting_team).
  def reports_waiting
    QuestionReport.awaiting_team.count
  end

  # Suggested problems nobody has decided on yet.
  def suggestions_waiting
    Question.in_review.count
  end

  def waiting
    reports_waiting + suggestions_waiting
  end

  # Answered, and now up to the student to say whether the fix worked —
  # nothing to do, but worth knowing about.
  def with_students
    QuestionReport.in_progress.where.not(id: QuestionReport.awaiting_team.select(:id)).count
  end

  def latest(limit = 5)
    QuestionReport.awaiting_team.includes(:question, :user).order(created_at: :desc).limit(limit)
  end
end
