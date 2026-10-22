# A session that prepares for one competition or exam: its topics, aimed a
# step above the student's everyday level.
#
# It never asks which grade the child is in. The event's grades say who the
# paper is for; what this child gets is the event's topics at *their* rating,
# exactly as every other session is chosen. A strong eight-year-old preparing
# for the Kangaroo gets hard Kangaroo-style problems and a struggling one gets
# easier ones, and both are on the right topics.
#
# Two deliberate differences from a daily session, and one non-difference:
#
#   * *Harder.* Competition problems sit above school problems by design, so
#     the session aims LIFT points over the usual target — about one problem
#     in two right rather than seven in ten. An exam (НВО, матура) is the
#     school programme, so it gets no lift.
#   * *Narrow.* Only the event's topics, so no spaced review and no frontier —
#     the student chose what to work on, the same stance MistakePractice takes.
#   * *Measured.* Unlike a mistakes session these are fresh problems chosen by
#     Dispatcher, so an answer is evidence like any other and moves the rating.
#     Deferrals still apply: a skipped type stays out here too.
module CompetitionPractice
  QUESTION_COUNT = 10

  # ~150 points above the target puts the expected success near 55%.
  LIFT = 150

  # Candidates drawn per slot, so the per-template cap has somewhere to go.
  OVERDRAW = 3

  NothingToPractise = Class.new(StandardError)

  module_function

  def execute(user:, event:, question_count: QUESTION_COUNT)
    questions = pick(user, event, question_count)
    raise NothingToPractise if questions.empty?

    assignment = Assignment.build(user: user, kind: :competition, competition_slug: event.slug)
    ActiveRecord::Base.transaction do
      questions.shuffle.each_with_index do |question, index|
        assignment.assignment_questions.build(question: question, position: index + 1)
      end
      assignment.save!
    end

    assignment
  end

  # Nearest the target first, then at most SessionComposer::MAX_PER_SHAPE of
  # any one template — a ladder family holds several variants of each rung, and
  # ten problems that are three problems with the numbers changed is not
  # preparation for anything. Short rather than padded off-topic when the
  # event's topics run out near the student.
  def pick(user, event, count)
    topic_ids = event.topic_ids
    return [] if topic_ids.empty?

    lift = event.exam? ? 0 : LIFT
    candidates = Dispatcher.pick(user, count: count * OVERDRAW, topic_ids: topic_ids, lift: lift)

    seen = Hash.new(0)
    candidates.select { |question| (seen[ProblemSeeds.shape_of(question.body_text.to_s)] += 1) <= SessionComposer::MAX_PER_SHAPE }
              .first(count)
  end
end
