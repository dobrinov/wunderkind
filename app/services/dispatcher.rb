# The one place that answers "which problems suit this student right now".
#
# There are no school grades anywhere in the model. A first-grader who can do
# third-grade work should be given third-grade work, and a fifth-grader who
# can't shouldn't be handed it because of the year they were born in. The only
# measure is the rating, so the dispatcher's whole job is to keep questions
# inside the band where a student is stretched but not stuck — and to find that
# band fast for someone who has no history for us to read.
module Dispatcher
  extend self

  # Aim for problems the student clears about seven times in ten: often enough
  # to keep moving, rarely enough that the misses still teach something.
  TARGET_SUCCESS_RATE = 0.7

  # Half-width of the band around the target the dispatcher will accept.
  BAND = 120

  # When the band can't fill a session, it widens in these Fibonacci steps
  # rather than returning short — see widening_pick.
  WIDENING_STEPS = [ 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181 ].freeze

  # Raised by everything that composes a set of questions (SessionComposer,
  # ChallengeMatchmaker) when even the widest band cannot fill it — the state a
  # database with no imported bank ships in.
  NotEnoughQuestions = Class.new(StandardError)

  # Attempted answers before a rating is worth trusting. Below this the
  # dispatcher stops aiming and starts searching.
  CALIBRATION_ANSWERS = 12

  # Used when the bank is empty, which is the state a fresh database ships in.
  FALLBACK_STARTING_RATING = 1000

  # How far above their current rating a calibration session reaches. One
  # session of rungs this far apart localizes a student to within a rung.
  CALIBRATION_CLIMB = 400

  # Free-text answers need a human grader the app no longer has, so they
  # never enter self-serve practice.
  def practice_pool
    Question.published.where.not(answer_type: Question.answer_types[:free_text])
  end

  # The pool minus what the student has said they haven't been taught: the
  # topics deferred by skipping (AnswerSubmission.defer_skill) and the problem
  # types they skipped. Both come back on their own once the deferral lapses.
  #
  # It also holds back topics school has not reached for this child
  # (`held_topic_ids`), except any named in `allow` — a parent's focus, a
  # competition, a frontier or review pick that asked for that topic by name.
  def available_pool(user, allow: [])
    scope = without_deferred(practice_pool, [ user ])
    scope = scope.where.not(id: recently_answered(user)) if user.respond_to?(:user_answers)
    held = held_topic_ids(user) - Array(allow)
    held.any? ? scope.where.not(id: Question.joins(:topics).where(topics: { id: held }).select(:id)) : scope
  end

  # Nothing answered in the last fortnight comes back on its own: the family
  # field test met yesterday's problems word for word, and placement problems
  # again in the first session after it. A mistake is re-asked on purpose by
  # „За преговор", which does not draw from here, and spaced review asks for a
  # topic again, not for the same question.
  RECENT_DAYS = 14

  def recently_answered(user)
    AssignmentQuestion.joins(:user_answer)
                      .where(user_answers: { user_id: user.id, created_at: RECENT_DAYS.days.ago.. })
                      .select(:question_id)
  end

  # How far ahead of a child's school grade the app reaches on its own.
  GRADE_REACH = 1

  # Topics school will not reach for this child for more than a year, by the
  # МОН programme (Curriculum::TOPICS) and the grade estimated from their birth
  # year — read only when a parent or the child gave one. In production a
  # quarter of all answers were „не съм го учил", and they were the topics a
  # first- or third-grader has not met: fractions and decimals skipped three
  # times in five, multiplication one in three. Elo alone cannot tell a hard
  # problem from an untaught one, which is the whole of this exception to
  # „there are no grades in the model".
  #
  # A child who has shown they can do a topic keeps it — one correct answer in
  # it is enough — so a first-grader who can do third-grade work still gets it.
  # Topics the programme never lists (or lists from first grade) are never
  # held, and a child with no birth year, or past school, holds nothing.
  def held_topic_ids(user)
    grade = user.respond_to?(:estimated_grade) ? user.estimated_grade : nil
    grade = 0 if grade == :preschool
    return [] unless grade.is_a?(Integer)

    beyond = Curriculum::TOPICS.select { |number, _| number > grade + GRADE_REACH }.values.flatten.uniq
    within = Curriculum::TOPICS.select { |number, _| number <= grade + GRADE_REACH }.values.flatten.uniq
    names = beyond - within
    return [] if names.empty?

    ids = Topic.where(name: names).pluck(:id)
    shown = UserAnswer.where(user: user, correct: true).joins(assignment_question: { question: :topics }).
      where(topics: { id: ids }).distinct.pluck("topics.id")
    ids - shown
  end

  def deferred_topic_ids(user)
    user.skills.where(deferred_until: Time.current..).pluck(:topic_id)
  end

  # Problem types — a question's text with its numbers blanked, the template
  # SessionComposer caps by — that the student marked „не съм го учил" within
  # the deferral window. The topic deferral alone could not catch these: it
  # only parks a topic the student has barely met (DEFERRAL_MAX_GAMES), and
  # the broad ones — „Умножение и деление", „Събиране и изваждане" — hold both
  # the table a child knows and the column addition they have not reached. A
  # third of the skips in production were the same type again within three
  # weeks: a child telling us something twice that we had already been told.
  # Read off the answers, so there is nothing to store and nothing to expire.
  def deferred_shapes(users)
    UserAnswer.where(user: users, skipped: true, created_at: AnswerSubmission::DEFERRAL_DAYS.days.ago..).
      joins(assignment_question: :question).
      distinct.
      pluck(Arel.sql(SessionComposer::SHAPE_SQL))
  end

  def without_deferred(scope, users)
    topics = users.flat_map { |user| deferred_topic_ids(user) }.uniq
    shapes = deferred_shapes(users)

    scope = scope.where.not(id: Question.joins(:topics).where(topics: { id: topics }).select(:id)) if topics.any?
    # A named bind, not "?": the regex literals in SHAPE_SQL contain "?" of
    # their own.
    scope = scope.where.not("#{SessionComposer::SHAPE_SQL} IN (:shapes)", shapes: shapes) if shapes.any?
    scope
  end

  # Measured, not merely attempted: a student who practised their mistakes
  # twice would otherwise leave calibration having been measured a third of
  # that many times, and the dispatcher would start aiming off a rating the
  # ladder never finished locating.
  #
  # A student who has sat the placement session is done: it bisected the bank
  # to find their rating and the ladder has nothing left to add. The ladder
  # remains for everyone who never sat one — accounts that predate it, and
  # anyone who skipped past it.
  def calibrating?(user)
    return false if user.placed_at.present?

    user.user_answers.measured.count < CALIBRATION_ANSWERS
  end

  # Inverting the Elo expectation turns a target success rate into a fixed
  # offset from the student's rating: at TARGET_SUCCESS_RATE = 0.7 the right
  # question sits ~147 points below them.
  def target_offset
    -(400 * Math.log10(TARGET_SUCCESS_RATE / (1 - TARGET_SUCCESS_RATE))).round
  end

  # The rating of the ideal next question for a student at `rating`.
  def target_rating(rating)
    [ rating + target_offset, 0 ].max
  end

  def band(rating)
    target = target_rating(rating)
    ((target - BAND)..(target + BAND))
  end

  # The easiest published problem there is, so a brand new student starts at
  # the very bottom of the bank rather than at an arbitrary constant.
  #
  # Starting low is the cheap mistake: a strong student is under-stretched for
  # a session and climbs out within a handful of answers — calibration reaches
  # CALIBRATION_CLIMB above wherever they stand — where a weak student started
  # high is handed problems they cannot even read and has no way to say so.
  # It is the floor and not a low percentile of the bank because a percentile
  # moves whenever the corpus does: the 10th once sat at 990, ten points under
  # RatingBand's novice ceiling, so a child who had answered nothing was shown
  # as one right answer from leaving the beginner band. The bands are fixed
  # numbers and the corpus is not, and the floor is the one point on the
  # distribution that means the same thing however the bank grows.
  def starting_rating
    practice_pool.minimum(:elo)&.round || FALLBACK_STARTING_RATING
  end

  # A calibration session is a ladder, not a band: rungs climbing from the
  # student's current rating so that wherever they stop getting them right is
  # their level. With the provisional K-factor in Elo, one session is usually
  # enough to land within a rung of the truth.
  def calibration_rungs(rating, count)
    return [] unless count.positive?
    return [ rating ] if count == 1

    step = CALIBRATION_CLIMB.to_f / (count - 1)
    Array.new(count) { |index| (rating + index * step).round }
  end

  # `count` questions for a student, nearest the right difficulty first.
  # Widens in Fibonacci steps rather than returning short, because a session
  # that fails to materialize helps nobody.
  #
  # `lift` aims that many points above the usual target, for a session that is
  # meant to be harder than everyday practice — preparing for a competition,
  # whose problems sit above the school ones by design.
  #
  # `reach` stops the widening at that many points either side of the target,
  # and returns short rather than going further: for a caller with something
  # else to fall back on, a short pick is better than problems far off the
  # student's level — a parent's focus (PracticeFocuses), which tops a short
  # session up with general practice.
  def pick(user, count:, excluding: [], topic_ids: nil, lift: 0, reach: nil)
    return [] unless count.positive?

    widening_pick(
      scoped_pool(user, topic_ids),
      rating: rating_for(user, topic_ids) + lift,
      count: count,
      excluding: excluding,
      reach: reach
    )
  end

  # One set of problems for two students at once, for a head-to-head match.
  # Both players see the same problems, so there is one target and it sits at
  # the midpoint of the two ratings; a topic or a problem type either of them
  # has deferred by skipping stays out, because a race is the worst possible place to meet
  # material you have told us you were never taught.
  def pick_shared(users, count:, topic_ids: nil)
    return [] unless count.positive?

    scope = without_deferred(practice_pool, users)
    scope = scope.where(id: Question.joins(:topics).where(topics: { id: topic_ids }).select(:id)) if topic_ids.present?

    widening_pick(scope, rating: (users.sum(&:elo).to_f / users.size).round, count: count)
  end

  # Ordered by how close each question sits to the student's target, so callers
  # that need to choose among candidates get the best fit first.
  # `reach` drops anything further than that from the target: without it
  # „nearest" means nearest *in the topic*, and a topic whose problems all sit
  # far above or below the child still handed over its closest ones — five
  # problems a thousand points away is a bad session, not a full one.
  def nearest(user, topic_ids: nil, reach: nil)
    target = target_rating(rating_for(user, topic_ids))

    scope = scoped_pool(user, topic_ids)
    scope = scope.where(elo: (target - reach)..(target + reach)) if reach

    # Ratings cluster on a handful of values, so hundreds of questions tie at
    # each one. Without a random tiebreak the ordering returns tied rows in
    # insertion order, which groups them by source and makes every session
    # repeat the same few templates.
    scope.order(Arel.sql("ABS(questions.elo - #{target.to_i}), RANDOM()"))
  end

  # The rating to aim from: the student's average over the topics in play, or
  # their overall rating when no topic is specified.
  def rating_for(user, topic_ids = nil)
    return user.elo if topic_ids.blank?

    ratings = user.skills.where(topic_id: topic_ids).pluck(:rating)
    ratings.any? ? (ratings.sum.to_f / ratings.size).round : user.elo
  end

  # The single question closest to one rung of a calibration ladder.
  def at_rung(user, rung:, topic_ids: nil, excluding: [])
    scoped_pool(user, topic_ids).
      where.not(id: excluding.map(&:id)).
      order(Arel.sql("ABS(questions.elo - #{rung.to_i}), RANDOM()")).
      first
  end

  private

  # Draws `count` questions from `scope` around the target for `rating`,
  # widening the band in Fibonacci steps until it has enough.
  def widening_pick(scope, rating:, count:, excluding: [], reach: nil)
    target = target_rating(rating)
    picked = []
    widths = [ BAND ] + WIDENING_STEPS
    widths = widths.select { |width| width < reach } + [ reach ] if reach

    widths.each do |width|
      break if picked.size >= count

      picked += scope.
        where.not(id: (excluding + picked).map(&:id)).
        where(elo: (target - width)..(target + width)).
        order("RANDOM()").
        limit(count - picked.size).
        to_a
    end

    picked
  end

  def scoped_pool(user, topic_ids)
    scope = available_pool(user, allow: topic_ids)
    return scope if topic_ids.blank?

    scope.where(id: Question.joins(:topics).where(topics: { id: topic_ids }).select(:id))
  end
end
