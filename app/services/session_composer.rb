# The adaptive session builder: instead of "N random questions near your Elo",
# a session mixes mostly frontier work (unlocked, unmastered topics), some
# spaced review of due topics, and one stretch question — with the plain
# near-Elo pool as filler so a session always materializes when questions exist.
module SessionComposer
  extend self

  REVIEW_SHARE = 0.2
  STRETCH_RANGE = (200..500)

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

  # Topics whose spaced review is due, nearest deadline first.
  def review_questions(user, count)
    return [] unless count.positive?

    due_topic_ids = user.skills.where(review_due_at: ..Time.current).order(:review_due_at).pluck(:topic_id)
    return [] if due_topic_ids.empty?

    near_rating_pool(user, topic_ids: due_topic_ids).limit(count).to_a
  end

  # Topics the curriculum graph has unlocked (all prerequisites mastered) and
  # the student hasn't mastered yet.
  def frontier_questions(user, count, excluding:)
    return [] unless count.positive?

    topic_ids = frontier_topic_ids(user)
    return [] if topic_ids.empty?

    near_rating_pool(user, topic_ids: topic_ids).
      where.not(id: excluding.map(&:id)).
      limit(count).
      to_a
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

    practice_pool.
      where(id: Question.joins(:topics).where(topics: { id: topic_ids }).select(:id)).
      order(Arel.sql("ABS(questions.elo - #{target.to_i})"))
  end

  def frontier_topic_ids(user)
    mastered_ids = user.skills.where.not(mastered_at: nil).pluck(:topic_id).to_set
    prerequisites = TopicPrerequisite.pluck(:topic_id, :prerequisite_id).group_by(&:first).transform_values { |pairs| pairs.map(&:last) }

    Topic.pluck(:id).select do |topic_id|
      next false if mastered_ids.include?(topic_id)

      (prerequisites[topic_id] || []).all? { |prerequisite_id| mastered_ids.include?(prerequisite_id) }
    end
  end
end
