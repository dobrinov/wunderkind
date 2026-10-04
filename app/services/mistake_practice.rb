# A session built from the questions a student got wrong and has not since got
# right — the one session in the app whose questions are not chosen by
# Dispatcher, because the student has already chosen them.
#
# Three decisions worth stating, because none of them is the obvious one.
#
# *Oldest first.* A mistake made this morning is still in mind and its
# explanation was read ten minutes ago; a mistake made three weeks ago is the
# one that has actually been forgotten, and is the only one re-asking tells us
# anything about. So the list drains from the far end.
#
# *Deferrals do not apply.* `Dispatcher.available_pool` drops topics the
# student has skipped, because the dispatcher is choosing on their behalf and
# must not hand back material they said they were never taught. Here the
# student is the one choosing, and a wrong answer is not a skip — they did
# attempt it. Only `practice_pool` applies, so a question withdrawn to draft or
# reserved for a grader we do not have stays out.
#
# *It measures nothing.* See Assignment#measured? — the rating movement is
# switched off for the whole session, and this is the service that knows why.
module MistakePractice
  DEFAULT_QUESTION_COUNT = 10

  NothingToPractise = Class.new(StandardError)

  module_function

  def execute(user:, question_count: DEFAULT_QUESTION_COUNT)
    questions = pick(user, question_count)
    raise NothingToPractise if questions.empty?

    assignment = Assignment.build(user: user, kind: :mistakes)
    ActiveRecord::Base.transaction do
      questions.each_with_index do |question, index|
        assignment.assignment_questions.build(question: question, position: index + 1)
      end
      assignment.save!
    end

    assignment
  end

  # Ordered by the mistake, not by the question row: the ids come back in the
  # order AnswerLog gives them and the questions are put back into it, since a
  # `where(id: ids)` returns rows in whatever order the planner likes.
  #
  # The pool filter comes *before* the truncation. A student whose ten oldest
  # mistakes were all on questions the report queue has since dropped to draft
  # still has forty live ones, and taking ten and then filtering would hand
  # them an empty session while the card promised ten — `available_count`
  # counts the same way, and the two have to agree.
  def pick(user, question_count)
    ids = AnswerLog.question_ids(AnswerLog.wrong(user))
    return [] if ids.empty?

    by_id = Dispatcher.practice_pool.where(id: ids).index_by(&:id)
    ids.filter_map { |id| by_id[id] }.first(question_count)
  end

  # What the button says, and whether it is offered at all. Counted over the
  # pool rather than over the log, so a student whose every mistake has since
  # been withdrawn is not promised a session that cannot be built.
  def available_count(user)
    Dispatcher.practice_pool.where(id: AnswerLog.wrong(user).select(:question_id)).count
  end
end
