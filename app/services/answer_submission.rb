# Orchestrates everything that happens when a student answers a question:
# grading, per-topic skill and question Elo updates, spaced-review scheduling,
# topic mastery, XP, streaks, badges, and session completion. The single entry
# point for the answer flow.
module AnswerSubmission
  AlreadyAnswered = Class.new(StandardError)

  Outcome = Struct.new(:answer, :result, :xp_earned, :new_badges, :assignment_completed, :mastered_topics, keyword_init: true)

  RECENT_GAMES_WINDOW = 6.months

  # SM-2-style ladder: each correct answer moves the topic's next review
  # further out; a wrong answer resets it to tomorrow.
  REVIEW_INTERVALS_DAYS = [ 1, 3, 7, 16, 35 ].freeze

  MASTERY_RATING = 1400
  MASTERY_MIN_GAMES = 10
  MASTERY_XP_BONUS = 50

  module_function

  def call(assignment_question:, user:, raw:, duration_ms: nil, hints_used: 0)
    raise AlreadyAnswered if assignment_question.user_answer.present?

    question = assignment_question.question
    assignment = assignment_question.assignment
    result = Grading.grade(question: question, raw: raw, user: user)

    skills = question.topics.map { |topic| user.skill_for(topic) }
    user_rating = skills.any? ? (skills.sum(&:rating).to_f / skills.size).round : user.elo
    question_rating_before = question.elo

    new_user_rating, new_question_elo = Elo.calculate_ratings(
      user_rating,
      question.elo,
      player_won: result.correct,
      player_games: user.user_answers.where(created_at: RECENT_GAMES_WINDOW.ago..).count,
      task_games: question.user_answers.where(created_at: RECENT_GAMES_WINDOW.ago..).count
    )
    rating_delta = new_user_rating - user_rating

    answer = assignment_question.build_user_answer(
      user: user,
      value: result.display_value,
      response: result.response.merge("hints_used" => hints_used.to_i),
      correct: result.correct,
      duration_ms: duration_ms
    )

    xp_earned = Xp.amount_for_answer(
      correct: result.correct,
      user_rating: user_rating,
      question_rating: question_rating_before
    )
    # Hints are for learning, not farming: a hinted correct answer pays half.
    xp_earned = [ xp_earned / 2, Xp::ATTEMPT_AMOUNT ].max if result.correct && hints_used.to_i.positive?

    new_badges = []
    mastered_topics = []
    assignment_completed = false

    ActiveRecord::Base.transaction do
      answer.save!

      skills.each do |skill|
        mastered_topics << update_skill(skill, rating_delta, result.correct)
      end
      mastered_topics.compact!

      question.update!(elo: new_question_elo)

      user.elo = [ user.elo + rating_delta, 0 ].max
      Xp.award!(user, amount: xp_earned, reason: "answer", source: answer)
      mastered_topics.each do |topic|
        xp_earned += Xp.award!(user, amount: MASTERY_XP_BONUS, reason: "topic_mastered", source: topic)
      end
      Streaks.record(user)

      if assignment.next_assignment_question.nil?
        assignment.update!(completed_at: Time.current)
        assignment_completed = true
        Xp.award!(user, amount: Xp::SESSION_BONUS, reason: "session_completed", source: assignment)
        xp_earned += Xp::SESSION_BONUS
      end

      user.save!

      new_badges += Badges.check!(user, {
        type: :answer_recorded,
        correct: result.correct,
        user_rating: user_rating,
        question_rating: question_rating_before
      })
      if assignment_completed
        new_badges += Badges.check!(user, { type: :session_completed, assignment: assignment })
      end
    end

    Outcome.new(
      answer: answer,
      result: result,
      xp_earned: xp_earned,
      new_badges: new_badges,
      assignment_completed: assignment_completed,
      mastered_topics: mastered_topics
    )
  end

  # Returns the topic if this update crossed the mastery threshold.
  def update_skill(skill, rating_delta, correct)
    new_rating = [ skill.rating + rating_delta, 0 ].max
    interval = correct ? next_review_interval(skill.review_interval_days) : REVIEW_INTERVALS_DAYS.first

    newly_mastered =
      skill.mastered_at.nil? &&
      new_rating >= MASTERY_RATING &&
      skill.games_count + 1 >= MASTERY_MIN_GAMES

    skill.update!(
      rating: new_rating,
      games_count: skill.games_count + 1,
      last_practiced_at: Time.current,
      review_interval_days: interval,
      review_due_at: interval.days.from_now,
      mastered_at: newly_mastered ? Time.current : skill.mastered_at
    )

    skill.topic if newly_mastered
  end

  def next_review_interval(current)
    REVIEW_INTERVALS_DAYS.find { |interval| interval > current } || REVIEW_INTERVALS_DAYS.last
  end
end
