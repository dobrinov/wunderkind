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
# Run on read, like Goals.refresh!, from the pages that list sessions — there
# is no job runner. Placements are left alone: Placement.unfinished resumes
# one, and it decides when a placement is over.
module StaleSessions
  STALE_AFTER = 1.day

  module_function

  def close!(user, now: Time.current)
    cutoff = now - STALE_AFTER

    user.assignments.where(completed_at: nil).where.not(kind: :placement).where(created_at: ...cutoff).find_each do |assignment|
      last_answer = assignment.user_answers.maximum(:created_at)
      next if last_answer && last_answer >= cutoff

      close(assignment, last_answer, now)
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
