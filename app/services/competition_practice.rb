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

  # Fewer than this many problems near the child is not a preparation
  # session, it is a sample — so the app says so and offers ordinary practice
  # instead (CompetitionPracticesController, competitions/_actions).
  MIN_QUESTIONS = 5

  NothingToPractise = Class.new(StandardError)

  module_function

  # The round already under way for this event, if there is one: pressing
  # „Подготви се" again — or twice in a second — went on making new sessions,
  # and „Упражнения" filled with „Продължи · Подготовка за СМТ" rows.
  def unfinished(user, event)
    user.assignments.competition.where(competition_slug: event.slug, completed_at: nil, abandoned_at: nil)
        .includes(assignment_questions: :user_answer).order(created_at: :desc)
        .find { |assignment| UnfinishedSessions.resumable?(assignment) }
  end

  def execute(user:, event:, question_count: QUESTION_COUNT)
    questions = pick(user, event, question_count)
    raise NothingToPractise if questions.size < [ MIN_QUESTIONS, question_count ].min

    assignment = Assignment.build(user: user, kind: :competition, competition_slug: event.slug)
    ActiveRecord::Base.transaction do
      questions.shuffle.each_with_index do |question, index|
        assignment.assignment_questions.build(question: question, position: index + 1)
      end
      assignment.save!
    end

    assignment
  end

  # Whether a session for this event would hold enough of its problems near
  # this child. The same pick the session makes, asked for MIN_QUESTIONS only.
  def ready?(user, event)
    pick(user, event, MIN_QUESTIONS).size >= MIN_QUESTIONS
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
    # Never below the event's own grades: a strong ninth-grader preparing for
    # a 5th-to-12th-grade tournament whose topics run out above was handed
    # even-and-odd sorting, because the pick widens until it finds something.
    floor = event.elo_range.begin
    # Half the session, where the bank has them, from this competition's own
    # problems — its past papers and ours on their model (PastPapers) — near
    # the same target; the rest from its topics as before, but never another
    # event's papers.
    # Past the grade hold: the child entered this event, and its problems are
    # set for its grades, not for the grade their birth year suggests.
    own = Dispatcher.pick(user, count: (count / 2.0).ceil, topic_ids: topic_ids, lift: lift,
                                source: event.slug, reach: SessionComposer::REACH, floor: floor, beyond_grade: true)
    candidates = own + Dispatcher.pick(user, count: count * OVERDRAW, topic_ids: topic_ids, lift: lift, excluding: own,
                                             sources_from: event.slug, floor: floor, beyond_grade: true)

    Templates.capped(candidates).first(count)
  end
end
