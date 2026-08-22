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

  # Where a brand new student starts, as a percentile of the published bank's
  # difficulty. Deliberately near the bottom: starting low is the cheap
  # mistake. A strong student is under-stretched for a session and climbs out
  # within a handful of answers, where a weak student started high is handed
  # problems they cannot even read.
  STARTING_PERCENTILE = 0.1

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

  # The pool minus topics the student has said they haven't been taught. Those
  # come back on their own once the deferral lapses — see
  # AnswerSubmission.defer_skill.
  def available_pool(user)
    deferred = deferred_topic_ids(user)
    return practice_pool if deferred.empty?

    practice_pool.where.not(id: Question.joins(:topics).where(topics: { id: deferred }).select(:id))
  end

  def deferred_topic_ids(user)
    user.skills.where(deferred_until: Time.current..).pluck(:topic_id)
  end

  def calibrating?(user)
    user.user_answers.attempted.count < CALIBRATION_ANSWERS
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

  # The 10th percentile of the published bank, so a new student meets the
  # easiest material we actually have rather than an arbitrary constant.
  def starting_rating
    percentile = practice_pool.pick(
      Arel.sql("percentile_cont(#{STARTING_PERCENTILE}) WITHIN GROUP (ORDER BY questions.elo)")
    )

    percentile&.round || FALLBACK_STARTING_RATING
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
  def pick(user, count:, excluding: [], topic_ids: nil)
    return [] unless count.positive?

    widening_pick(
      scoped_pool(user, topic_ids),
      rating: rating_for(user, topic_ids),
      count: count,
      excluding: excluding
    )
  end

  # One set of problems for two students at once, for a head-to-head match.
  # Both players see the same problems, so there is one target and it sits at
  # the midpoint of the two ratings; a topic either of them has deferred by
  # skipping stays out, because a race is the worst possible place to meet
  # material you have told us you were never taught.
  def pick_shared(users, count:)
    return [] unless count.positive?

    deferred = users.flat_map { |user| deferred_topic_ids(user) }.uniq
    scope = practice_pool
    scope = scope.where.not(id: Question.joins(:topics).where(topics: { id: deferred }).select(:id)) if deferred.any?

    widening_pick(scope, rating: (users.sum(&:elo).to_f / users.size).round, count: count)
  end

  # Ordered by how close each question sits to the student's target, so callers
  # that need to choose among candidates get the best fit first.
  def nearest(user, topic_ids: nil)
    target = target_rating(rating_for(user, topic_ids))

    # Ratings cluster on a handful of values, so hundreds of questions tie at
    # each one. Without a random tiebreak the ordering returns tied rows in
    # insertion order, which groups them by source and makes every session
    # repeat the same few templates.
    scoped_pool(user, topic_ids).order(Arel.sql("ABS(questions.elo - #{target.to_i}), RANDOM()"))
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
  def widening_pick(scope, rating:, count:, excluding: [])
    target = target_rating(rating)
    picked = []

    ([ BAND ] + WIDENING_STEPS).each do |width|
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
    scope = available_pool(user)
    return scope if topic_ids.blank?

    scope.where(id: Question.joins(:topics).where(topics: { id: topic_ids }).select(:id))
  end
end
