# The sessions a student started and can still go back to, for a „Продължи"
# row on „Днес" and „Упражнения".
#
# Only the daily session used to be resumed (DailyPractice.unfinished_today);
# a topic session closed at 2 of 10, a competition round or a running mock
# exam had no way back, and pressing the button again started a new one —
# the agent field test lost a mock at 18 of 20 that way. A session counts
# until StaleSessions would close it, a mock until its clock runs out. Placement
# has its own door, and the daily session is the hero's own button.
module UnfinishedSessions
  LIMIT = 2

  module_function

  def for(user, limit: LIMIT)
    user.assignments.where(completed_at: nil, abandoned_at: nil)
        .where.not(kind: %i[placement daily])
        .includes(assignment_questions: [ :user_answer, { question: :topics } ])
        .order(created_at: :desc)
        .select { |assignment| resumable?(assignment) }
        .first(limit)
  end

  def resumable?(assignment)
    return false if assignment.mock? && MockExam.over?(assignment)

    answers = assignment.assignment_questions.filter_map(&:user_answer)
    return false if answers.size == assignment.assignment_questions.size
    return true if assignment.mock? # a mock is over when its clock says so

    !StaleSessions.stale?(assignment, answers.map(&:created_at).max)
  end

  def next_row(assignment) = assignment.assignment_questions.sort_by(&:position).find { |row| row.user_answer.nil? }
  def answered(assignment) = assignment.assignment_questions.count { |row| row.user_answer.present? }

  # What the row calls it: the exam or paper, the competition, or the topic
  # the session was about.
  def title(assignment)
    event = assignment.competition_slug && Competitions.find(assignment.competition_slug)
    name = event && (event.short.presence || event.name.to_s)
    case assignment.kind
    when "mock"
      if assignment.paper_year
        I18n.t("unfinished.paper", name: name, year: assignment.paper_year, grade: assignment.paper_grade)
      else
        I18n.t("unfinished.mock", name: name)
      end
    when "competition" then I18n.t("unfinished.competition", name: name)
    when "mistakes" then I18n.t("unfinished.mistakes")
    else
      topics = assignment.assignment_questions.flat_map { |row| row.question.topics }.map(&:name).tally
      topics.size == 1 ? I18n.t("unfinished.topic", name: topics.keys.first) : I18n.t("unfinished.practice")
    end
  end

  def minutes_left(assignment)
    return unless assignment.mock?

    [ ((MockExam.deadline(assignment) - Time.current) / 60).ceil, 1 ].max
  end
end
