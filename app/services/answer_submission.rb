# Orchestrates everything that happens when a student answers a question:
# grading, per-topic skill and question Elo updates, XP, streaks, badges,
# and session completion. The single entry point for the answer flow.
module AnswerSubmission
  AlreadyAnswered = Class.new(StandardError)

  Outcome = Struct.new(:answer, :result, :xp_earned, :new_badges, :assignment_completed, keyword_init: true)

  RECENT_GAMES_WINDOW = 6.months

  module_function

  def call(assignment_question:, user:, raw:, duration_ms: nil)
    raise AlreadyAnswered if assignment_question.user_answer.present?

    question = assignment_question.question
    assignment = assignment_question.assignment
    result = Grading.grade(question: question, raw: raw)

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
      response: result.response,
      correct: result.correct,
      duration_ms: duration_ms
    )

    xp_earned = Xp.amount_for_answer(
      correct: result.correct,
      user_rating: user_rating,
      question_rating: question_rating_before
    )

    new_badges = []
    assignment_completed = false

    ActiveRecord::Base.transaction do
      answer.save!

      skills.each do |skill|
        skill.update!(
          rating: [ skill.rating + rating_delta, 0 ].max,
          games_count: skill.games_count + 1,
          last_practiced_at: Time.current
        )
      end

      question.update!(elo: new_question_elo)

      user.elo = [ user.elo + rating_delta, 0 ].max
      Xp.award!(user, amount: xp_earned, reason: "answer", source: answer)
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
      assignment_completed: assignment_completed
    )
  end
end
