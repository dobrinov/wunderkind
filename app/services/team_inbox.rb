# What is waiting on the team, counted once for every place that says so:
# the „Входящи" badge in the admin menu, the badge on „Администрация" in the
# workspace switch, and „Чака нас" on the dashboard. One module so the three
# cannot disagree about what "waiting" means — reports and suggestions are
# both tickets (QuestionReport#kind), waiting when the last word is not the
# team's (QuestionReport.awaiting_team).
module TeamInbox
  module_function

  def waiting
    QuestionReport.waiting_count
  end

  def by_kind
    QuestionReport.waiting_counts_by_kind
  end

  # Answered, and now up to the student to say whether the fix worked —
  # nothing to do, but worth knowing about.
  def with_students
    QuestionReport.report.in_progress.where.not(id: QuestionReport.awaiting_team.select(:id)).count
  end

  def latest(limit = 5)
    QuestionReport.awaiting_team.includes(:question, :user).order(created_at: :desc).limit(limit)
  end
end
