# What a student got wrong, and what they said they had never been taught —
# read back as a list of *questions* rather than of answers.
#
# That distinction is the whole of this file. A student meets the same question
# more than once (nothing in Dispatcher excludes a question they have seen, and
# a mistakes session deliberately serves them again), so "my mistakes" cannot
# be `user_answers.where(correct: false)`: a question got wrong in March and
# right in April would sit in the list forever, which is precisely the opposite
# of what the list is for. Only the *latest* answer to each question counts, so
# the list drains as the student fixes things, and a question leaves it by
# being answered correctly — never by being quietly dropped.
#
# DISTINCT ON is Postgres-only, which this app already is (db/structure.sql).
module AnswerLog
  module_function

  # Wrong, and still wrong. A pending free-text answer is excluded by name
  # rather than by `correct: false`: it is waiting for a grader, not marked
  # down — the same fourth outcome the review screen knows. `IS DISTINCT FROM`
  # and not `!=`, because the key is absent on every other answer and `NULL !=
  # 'x'` is NULL, which would empty the list.
  def wrong(user)
    outstanding(user).
      where(skipped: false, correct: false).
      where("user_answers.response ->> 'verdict' IS DISTINCT FROM 'pending_review'")
  end

  def skipped(user)
    outstanding(user).where(skipped: true)
  end

  # The question ids behind a list, newest-answered last — see
  # MistakePractice for why that order is the one worth having.
  def question_ids(scope)
    scope.reorder(created_at: :asc).pluck(:question_id)
  end

  # One row per question: the student's most recent answer to it. Selected into
  # a subquery rather than grouped in Ruby so the counts on the review page
  # stay one query each however long a student has been practising.
  def latest_per_question(user)
    UserAnswer.
      joins(:assignment_question).
      where(user: user).
      select("DISTINCT ON (assignment_questions.question_id) user_answers.*, assignment_questions.question_id AS question_id").
      order("assignment_questions.question_id, user_answers.created_at DESC")
  end

  def outstanding(user)
    UserAnswer.from(latest_per_question(user), :user_answers).order(created_at: :desc)
  end
end
