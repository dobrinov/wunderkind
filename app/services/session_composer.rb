# The adaptive session builder: instead of "N random questions near your Elo",
# a session mixes mostly frontier work (unlocked, unmastered topics), some
# spaced review of due topics, and one stretch question — with the plain
# near-Elo pool as filler so a session always materializes when questions exist.
module SessionComposer
  extend self

  REVIEW_SHARE = 0.2

  # A stretch problem should be a harder problem at the student's own level,
  # not next year's material. One grade is 130 rating points, so staying under
  # ~200 keeps the stretch inside the student's grade band (whose tiers span
  # intro −60 to competition +280).
  STRETCH_RANGE = (90..200)

  # Free-text answers need a human grader, so they only appear in homework
  # (where the assigner reviews them) — never in self-serve practice.
  def practice_pool
    Question.published.where.not(answer_type: Question.answer_types[:free_text])
  end

  def execute(user:, question_count:, kind: :practice, feedback_after_answer: nil)
    picked = []

    review_count = (question_count * REVIEW_SHARE).round
    stretch_count = question_count >= 5 ? 1 : 0

    picked += review_questions(user, review_count)
    picked += stretch_questions(user, stretch_count, excluding: picked)
    picked += frontier_questions(user, question_count - picked.size, excluding: picked)
    picked += filler_questions(user, question_count - picked.size, excluding: picked)

    raise AssignmentCreator::NotEnoughQuestions, "Not enough questions found" if picked.size < question_count

    picked = diversify(user, picked)

    assignment = Assignment.build(user:, kind:, feedback_after_answer:)
    ActiveRecord::Base.transaction do
      picked.shuffle.each_with_index do |question, index|
        assignment.assignment_questions.build(question:, position: index + 1)
      end
      assignment.save!
    end

    assignment
  end

  private

  # Cap on problems sharing one template per session. MAX_PER_TOPIC is not
  # enough on its own: the fact tables put thousands of "a + b" drills in one
  # topic, so a young student's near-Elo pool is almost entirely one template
  # and every stage below would draw from it.
  MAX_PER_SHAPE = 2

  # Candidates fetched per over-quota slot. Replacements are drawn by closeness
  # to the student's rating, so a handful of alternatives is plenty.
  REPLACEMENT_FETCH = 12

  # Swaps out problems past the per-template cap for others near the student's
  # rating. Falls back to the original problem when nothing else fits, so a
  # session never shrinks below the requested count.
  def diversify(user, picked)
    seen = Hash.new(0)
    keep, excess = picked.partition { |question| (seen[shape_of(question)] += 1) <= MAX_PER_SHAPE }
    return picked if excess.empty?

    excess.each { |question| seen[shape_of(question)] -= 1 }
    # The templates already in the session have to be excluded in the query,
    # not filtered afterwards: near a young student's rating almost every
    # problem is one of them, so a plain nearest-rating fetch would come back
    # with no usable alternative.
    candidates = replacement_candidates(user, picked, seen.keys, excess.size)

    excess.each do |dropped|
      replacement = candidates.find do |candidate|
        keep.exclude?(candidate) && seen[shape_of(candidate)] < MAX_PER_SHAPE
      end

      keep << (replacement || dropped)
      seen[shape_of(replacement || dropped)] += 1
    end

    keep
  end

  # ProblemSeeds.shape_of in SQL, so saturated templates can be filtered out
  # before the rating ordering picks a winner.
  SHAPE_SQL = "btrim(regexp_replace(regexp_replace(questions.body_text, '\\d+([.,]\\d+)?', '#', 'g'), '\\s+', ' ', 'g'))".freeze

  def replacement_candidates(user, picked, saturated, count)
    practice_pool.
      where.not(id: picked.map(&:id)).
      # A named bind, not "?": the regex literals contain "?" of their own,
      # which a positional bind list would try to fill in.
      where.not("#{SHAPE_SQL} IN (:shapes)", shapes: saturated).
      order(Arel.sql("ABS(questions.elo - #{user.elo.to_i}), RANDOM()")).
      limit(count * REPLACEMENT_FETCH).
      to_a
  end

  def shape_of(question)
    ProblemSeeds.shape_of(question.body_text)
  end

  # Topics whose spaced review is due, nearest deadline first.
  def review_questions(user, count)
    return [] unless count.positive?

    due_topic_ids = user.skills.where(review_due_at: ..Time.current).order(:review_due_at).pluck(:topic_id)
    return [] if due_topic_ids.empty?

    near_rating_pool(user, topic_ids: due_topic_ids).limit(count).to_a
  end

  # Topics the curriculum graph has unlocked (all prerequisites mastered) and
  # the student hasn't mastered yet.
  # Spread across topics rather than filling the session from whichever topic
  # happens to sort first: a session of ten angle questions is a worksheet, not
  # practice.
  MAX_PER_TOPIC = 3

  def frontier_questions(user, count, excluding:)
    return [] unless count.positive?

    topic_ids = frontier_topic_ids(user).shuffle
    return [] if topic_ids.empty?

    picked = []
    per_topic = [ (count.to_f / topic_ids.size).ceil, MAX_PER_TOPIC ].min

    topic_ids.each do |topic_id|
      break if picked.size >= count

      picked += near_rating_pool(user, topic_ids: [ topic_id ]).
        where.not(id: (excluding + picked).map(&:id)).
        limit([ per_topic, count - picked.size ].min).
        to_a
    end

    picked
  end

  def stretch_questions(user, count, excluding:)
    return [] unless count.positive?

    practice_pool.
      where.not(id: excluding.map(&:id)).
      where(elo: (user.elo + STRETCH_RANGE.min)..(user.elo + STRETCH_RANGE.max)).
      order("RANDOM()").
      limit(count).
      to_a
  end

  # Plain near-Elo filler with widening steps — the old behavior, as a floor.
  def filler_questions(user, count, excluding:)
    return [] unless count.positive?

    picked = []
    AssignmentCreator::RANGE_STEPS.each do |step|
      break if picked.size >= count

      picked += practice_pool.
        where.not(id: (excluding + picked).map(&:id)).
        where(elo: (user.elo - step)..(user.elo + step)).
        order("RANDOM()").
        limit(count - picked.size).
        to_a
    end

    if picked.size < count
      picked += practice_pool.
        where.not(id: (excluding + picked).map(&:id)).
        order("RANDOM()").
        limit(count - picked.size).
        to_a
    end

    picked
  end

  def near_rating_pool(user, topic_ids:)
    ratings = user.skills.where(topic_id: topic_ids).pluck(:rating)
    target = ratings.any? ? (ratings.sum.to_f / ratings.size).round : user.elo

    # Ratings are derived from grade and tier, so hundreds of questions share
    # each value. Without a random tiebreak the closest-rating ordering returns
    # tied rows in insertion order, which groups them by generator and makes
    # every session repeat the same few templates.
    practice_pool.
      where(id: Question.joins(:topics).where(topics: { id: topic_ids }).select(:id)).
      order(Arel.sql("ABS(questions.elo - #{target.to_i}), RANDOM()"))
  end

  def frontier_topic_ids(user)
    mastered_ids = user.skills.where.not(mastered_at: nil).pluck(:topic_id).to_set
    prerequisites = TopicPrerequisite.pluck(:topic_id, :prerequisite_id).group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
    entry_ratings = topic_entry_ratings

    Topic.pluck(:id).select do |topic_id|
      next false if mastered_ids.include?(topic_id)

      (prerequisites[topic_id] || []).all? do |prerequisite_id|
        mastered_ids.include?(prerequisite_id) || outgrown?(user, prerequisite_id, entry_ratings)
      end
    end
  end

  # Prerequisites gate progression, not initial access. A new student has
  # mastered nothing in our records, but a fifth-grader is not thereby a
  # beginner at addition — locking them out of fractions until they formally
  # "master" it would leave them practising four topics. A prerequisite also
  # counts as satisfied once the student's rating has clearly passed the level
  # that topic is pitched at.
  OUTGROWN_MARGIN = 60

  def outgrown?(user, topic_id, entry_ratings)
    entry = entry_ratings[topic_id]
    entry.present? && user.elo >= entry + OUTGROWN_MARGIN
  end

  # The rating a topic is pitched at: the median rating of its questions.
  def topic_entry_ratings
    Question.published.
      joins(:topics).
      group("topics.id").
      pluck(Arel.sql("topics.id, percentile_cont(0.5) WITHIN GROUP (ORDER BY questions.elo)")).
      to_h
  end
end
