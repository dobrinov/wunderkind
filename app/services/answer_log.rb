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
# being answered correctly — or, for a mistake, by waiting MISTAKE_DAYS
# without a second try.
#
# DISTINCT ON is Postgres-only, which this app already is (db/structure.sql).
module AnswerLog
  # How long a mistake waits for its second try before it leaves the list.
  # A mistake nobody came back to for three weeks says little about the
  # child now — in the meantime they have practised and usually moved on —
  # and the list only grew: in production one child's card said „100 задачи
  # чакат втори опит", two thirds of them over two weeks old and nearly half
  # on problems now far below their level. Three weeks is well past
  # Xp::RECALL_AFTER_DAYS, so the retries spaced practice is for stay. The
  # answer itself stays in the history; only the list lets it go.
  MISTAKE_DAYS = 21

  module_function

  # Wrong, and still wrong, and recent enough to be worth a second try. A
  # pending free-text answer is excluded by name rather than by `correct:
  # false`: it is waiting for a grader, not marked down — the same fourth
  # outcome the review screen knows. `IS DISTINCT FROM` and not `!=`, because
  # the key is absent on every other answer and `NULL != 'x'` is NULL, which
  # would empty the list.
  def wrong(user)
    outstanding(user).
      where(skipped: false, correct: false).
      where(created_at: MISTAKE_DAYS.days.ago..).
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
  #
  # A retired question is left out. It can never be served again, so it can
  # never be answered correctly and could never leave either list — it would
  # sit there for good and the mistakes count would never reach zero. A draft
  # one stays: the report queue's withdraw is reversible, and the question is
  # back in practice the day it is fixed. The answers themselves are untouched
  # and still show in the student's history.
  def latest_per_question(user)
    UserAnswer.
      joins(assignment_question: :question).
      where(user: user).
      where.not(questions: { status: :retired }).
      select("DISTINCT ON (assignment_questions.question_id) user_answers.*, assignment_questions.question_id AS question_id").
      order("assignment_questions.question_id, user_answers.created_at DESC")
  end

  def outstanding(user)
    UserAnswer.from(latest_per_question(user), :user_answers).order(created_at: :desc)
  end
end
