module NextQuestion
  extend self

  BEGINNER_RANGE = 50
  INTERMEDIATE_RANGE = 75
  ADVANCED_RANGE = 100
  FALLBACK_RANGES = [ 150, 250, 400, 600 ]

  def for(assignment)
    return if assignment.completed_at?
    return if assignment.questions.count >= assignment.question_count
    return assignment.unanswered_questions.first if assignment.unanswered_questions.any?

    user = assignment.user
    excluded_ids = assignment.question_ids

    find_optimal_question(user, excluded_ids) || find_fallback_question(user, excluded_ids)
  end

  private

  def find_optimal_question(user, excluded_ids)
    user_elo = user.elo
    optimal_range = optimal_range_for_user(user_elo)

    candidates =
      Question.
        where.not(id: excluded_ids).
        where(elo: (user_elo - optimal_range)..(user_elo + optimal_range)).
        limit(300)

    return nil if candidates.empty?

    candidates.
      sort_by { |question| [ question.elo < user_elo ? 0 : 1, (question.elo - user_elo).abs ] }.
      first
  end

  def find_fallback_question(user, excluded_ids)
    user_elo = user.elo

    FALLBACK_RANGES.each do |range|
      question = Question.where.not(id: excluded_ids)
                        .where(elo: (user_elo - range)..(user_elo + range))
                        .order("RANDOM()")
                        .first
      return question if question.present?
    end

    # Last resort: any question not already used
    Question.where.not(id: excluded_ids).order("RANDOM()").first
  end

  def optimal_range_for_user(user_elo)
    case user_elo
    when 0...1000
      BEGINNER_RANGE
    when 1000...1500
      INTERMEDIATE_RANGE
    else
      ADVANCED_RANGE
    end
  end
end
