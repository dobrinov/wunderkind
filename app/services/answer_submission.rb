# Orchestrates everything that happens when a student answers a question:
# grading, per-topic skill and question Elo updates, spaced-review scheduling,
# topic mastery, XP, streaks, badges, and session completion. The single entry
# point for the answer flow.
module AnswerSubmission
  AlreadyAnswered = Class.new(StandardError)
  BlankResponse = Class.new(StandardError)

  Outcome = Struct.new(:answer, :result, :xp_earned, :new_badges, :assignment_completed, :mastered_topics, keyword_init: true)

  RECENT_GAMES_WINDOW = 6.months

  # SM-2-style ladder: each correct answer moves the topic's next review
  # further out; a wrong answer resets it to tomorrow.
  REVIEW_INTERVALS_DAYS = [ 1, 3, 7, 16, 35 ].freeze

  MASTERY_RATING = 1400
  MASTERY_MIN_GAMES = 10
  MASTERY_XP_BONUS = 50

  module_function

  def call(assignment_question:, user:, raw:, duration_ms: nil)
    raise AlreadyAnswered if assignment_question.user_answer.present?

    # Counted by HintRevealsController as it served each rung — never taken
    # from the request, because the halving below makes the number worth lying
    # about.
    hints_used = assignment_question.hints_revealed

    question = assignment_question.question
    raise BlankResponse if Grading.blank_response?(question: question, raw: raw)

    assignment = assignment_question.assignment
    result = Grading.grade(question: question, raw: raw, user: user)

    skills = question.topics.map { |topic| user.skill_for(topic) }
    user_rating = skills.any? ? (skills.sum(&:rating).to_f / skills.size).round : user.elo
    question_rating_before = question.elo
    player_games = user.user_answers.attempted.where(created_at: RECENT_GAMES_WINDOW.ago..).count
    task_games = question.user_answers.attempted.where(created_at: RECENT_GAMES_WINDOW.ago..).count

    new_user_rating, new_question_elo = Elo.calculate_ratings(
      user_rating,
      question.elo,
      player_won: result.correct,
      player_games: player_games,
      task_games: task_games
    )
    rating_delta = new_user_rating - user_rating

    # The overall rating plays the same game, but from its own baseline. It
    # must not take the per-topic delta above: that one is measured against the
    # topics' skill average, and an improving student's stale skills sit low,
    # so against them every win looks like an upset — adding those subsidized
    # deltas to user.elo inflated it without bound (~500 points over ten
    # simulated weeks) while the skills themselves stayed honest.
    new_user_elo, _ = Elo.calculate_ratings(
      user.elo,
      question.elo,
      player_won: result.correct,
      player_games: player_games,
      task_games: task_games
    )

    answer = assignment_question.build_user_answer(
      user: user,
      value: result.display_value,
      response: result.response.merge("hints_used" => hints_used),
      correct: result.correct,
      duration_ms: duration_ms
    )

    xp_earned = Xp.amount_for_answer(
      correct: result.correct,
      user_rating: user_rating,
      question_rating: question_rating_before
    )
    # Hints are for learning, not farming: a hinted correct answer pays half.
    xp_earned = [ xp_earned / 2, Xp::ATTEMPT_AMOUNT ].max if result.correct && hints_used.positive?

    new_badges = []
    mastered_topics = []
    assignment_completed = false

    # The AlreadyAnswered check above reads before this writes, so two racing
    # requests (a double-click, a replayed form) can both get past it. The
    # unique index on user_answers.assignment_question_id makes the loser's
    # save fail instead of double-moving Elo and double-awarding XP, and the
    # failure wears the same error the check raises, so callers see one
    # condition, not two.
    ActiveRecord::Base.transaction do
      save_answer!(answer)

      skills.each do |skill|
        mastered_topics << update_skill(skill, rating_delta, result.correct)
      end
      mastered_topics.compact!

      question.update!(elo: new_question_elo)

      user.elo = new_user_elo
      Xp.award!(user, amount: xp_earned, reason: "answer", source: answer)
      mastered_topics.each do |topic|
        xp_earned += Xp.award!(user, amount: MASTERY_XP_BONUS, reason: "topic_mastered", source: topic)
      end
      Streaks.record(user)

      if complete_if_finished(assignment)
        assignment_completed = true
        xp_earned += Xp.award!(user, amount: Xp::SESSION_BONUS, reason: "session_completed", source: assignment)
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

  # "I haven't been taught this yet." Deliberately not a wrong answer: the
  # student's own rating, XP and streak are left alone, because a gap in what
  # school has covered says nothing about how good they are. What it does say
  # is that the question sits outside their curriculum so far, so the question
  # rating rises a little and the topic is parked for a while.
  def skip(assignment_question:, user:, duration_ms: nil)
    raise AlreadyAnswered if assignment_question.user_answer.present?

    question = assignment_question.question
    assignment = assignment_question.assignment

    skills = question.topics.map { |topic| user.skill_for(topic) }
    user_rating = skills.any? ? (skills.sum(&:rating).to_f / skills.size).round : user.elo

    answer = assignment_question.build_user_answer(
      user: user,
      value: "",
      response: { "skipped" => true },
      correct: false,
      skipped: true,
      duration_ms: duration_ms
    )

    xp_earned = 0
    new_badges = []
    assignment_completed = false

    ActiveRecord::Base.transaction do
      save_answer!(answer)
      question.update!(elo: question.elo + Elo.skip_adjustment(user_rating: user_rating, question_rating: question.elo))
      skills.each { |skill| defer_skill(skill) }

      if complete_if_finished(assignment)
        assignment_completed = true

        # A session the student only shrugged their way through is not a
        # session completed: neither the bonus nor the session badges are due
        # until at least one question was really attempted.
        if assignment.user_answers.attempted.exists?
          xp_earned += Xp.award!(user, amount: Xp::SESSION_BONUS, reason: "session_completed", source: assignment)
          user.save!
          new_badges += Badges.check!(user, { type: :session_completed, assignment: assignment })
        end
      end
    end

    Outcome.new(
      answer: answer,
      result: nil,
      xp_earned: xp_earned,
      new_badges: new_badges,
      assignment_completed: assignment_completed,
      mastered_topics: []
    )
  end

  # Only this save translates the unique-index violation: badge awards carry a
  # unique index of their own, and a conflict there is not a double answer.
  def save_answer!(answer)
    answer.save!
  rescue ActiveRecord::RecordNotUnique
    raise AlreadyAnswered
  end

  def complete_if_finished(assignment)
    return false if assignment.next_assignment_question.present?

    assignment.update!(completed_at: Time.current)
    true
  end

  # How long a skipped topic stays out of the rotation. Long enough for school
  # to have moved on, short enough that a student who skipped once out of
  # nerves is not locked out of a topic for a term.
  DEFERRAL_DAYS = 21

  # Only park topics the student has barely met. Once there is real history on a
  # topic, a skip is far more likely to be one odd question — a stray tag, an
  # unfamiliar phrasing — than a gap in the curriculum, and pulling the whole
  # topic for three weeks would cost more than it saves.
  DEFERRAL_MAX_GAMES = 5

  # Deliberately leaves rating and games_count alone: a skip is not evidence
  # about the student, only about what they have been shown.
  def defer_skill(skill)
    return if skill.games_count >= DEFERRAL_MAX_GAMES

    deferred_until = DEFERRAL_DAYS.days.from_now
    skill.update!(
      deferred_until: deferred_until,
      review_due_at: [ skill.review_due_at, deferred_until ].compact.max
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
