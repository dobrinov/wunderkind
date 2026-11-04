# Closes the sessions a student walked away from.
#
# Nothing else ever does: a new session is composed every time „Упражнявай"
# is pressed, so one left half-done on Tuesday sits on the history with a
# „Продължи" link for good, and a student who practises most days collects
# dozens. A session nobody has touched for STALE_AFTER is over in every sense
# but the column.
#
# Closing it works the way retiring a question settles a session (see
# Question#leave_unfinished_sessions): the unanswered rows go, the answered
# ones stay — they are the student's history — and a session with no answers
# at all is deleted. completed_at is the time of the last answer, so the
# session's length on the history is the time actually spent; abandoned_at
# keeps it out of the session badges, which are for finishing one.
#
# A session nobody answered anything in goes sooner, after UNTOUCHED_AFTER:
# it holds no history, only a „Продължи 0 от 10" row, and a child who pressed
# a button and wandered off has not started anything worth going back to.
#
# Run on read, like Goals.refresh!, from the pages that list sessions — there
# is no job runner. Placements are left alone: Placement.unfinished resumes
# one, and it decides when a placement is over.
module StaleSessions
  STALE_AFTER = 1.day
  UNTOUCHED_AFTER = 1.hour

  module_function

  def close!(user, now: Time.current)
    finish_mocks!(user)

    user.assignments.where(completed_at: nil).where.not(kind: %i[placement mock]).where(created_at: ...(now - UNTOUCHED_AFTER)).find_each do |assignment|
      last_answer = assignment.user_answers.maximum(:created_at)
      close(assignment, last_answer, now) if stale?(assignment, last_answer, now)
    end
  end

  # Over a day since the last answer, or an hour since it was made if it has
  # none. UnfinishedSessions asks the same, so a row never offers what the
  # next visit would close.
  def stale?(assignment, last_answer, now = Time.current)
    last_answer ? last_answer < now - STALE_AFTER : assignment.created_at < now - UNTOUCHED_AFTER
  end

  # A mock exam whose clock ran out is over the way the paper says: finished,
  # scored out of the whole paper, the unanswered counting as not done — not
  # walked away from. One left at 18 of 20 overnight used to vanish with its
  # result. With no answer at all there is nothing to show, so it goes.
  def finish_mocks!(user)
    user.assignments.mock.where(completed_at: nil).find_each do |assignment|
      next unless MockExam.over?(assignment)

      assignment.user_answers.exists? ? MockExam.finish!(assignment) : assignment.destroy!
    end
  end

  def close(assignment, last_answer, now)
    Assignment.transaction do
      assignment.assignment_questions.left_joins(:user_answer).where(user_answers: { id: nil }).destroy_all

      if last_answer
        assignment.update!(completed_at: last_answer, abandoned_at: now)
      else
        assignment.destroy!
      end
    end
  end
end
