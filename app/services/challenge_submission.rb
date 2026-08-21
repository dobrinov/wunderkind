# Everything that happens when a student answers inside a duel, and everything
# that happens when the duel ends.
#
# Deliberately *not* AnswerSubmission. A duel is a game, so it pays XP and
# counts for the daily streak — the child really did the maths — but it leaves
# every measurement alone: no per-topic skill update, no question Elo update, no
# calibration progress. Answers given against a clock with an opponent on the
# screen are noisier than answers given in practice, and the rating that decides
# what a student is shown next is too important to feed with them.
module ChallengeSubmission
  AlreadyAnswered = Class.new(StandardError)
  BlankResponse = Class.new(StandardError)
  OutOfTime = Class.new(StandardError)

  Outcome = Struct.new(:answer, :result, :points, :xp_earned, :participant_finished, keyword_init: true)

  module_function

  # Starts this player's clock on the problem in front of them. Only stamps an
  # unstamped problem, so reloading the page cannot buy thinking time.
  def serve(participant)
    participant.update!(question_started_at: Time.current) if participant.question_started_at.nil?
    participant
  end

  def call(participant:, challenge_question:, raw:)
    challenge = participant.challenge
    raise OutOfTime unless challenge.active? && !challenge.out_of_time?
    raise AlreadyAnswered if participant.answer_for(challenge_question)

    question = challenge_question.question
    raise BlankResponse if Grading.blank_response?(question: question, raw: raw)

    user = participant.user
    result = Grading.grade(question: question, raw: raw, user: user)
    duration_ms = elapsed_ms(participant)
    points = ChallengeScoring.points(
      correct: result.correct,
      duration_ms: duration_ms,
      seconds_per_question: challenge.seconds_per_question
    )
    xp_earned = Xp.amount_for_answer(
      correct: result.correct,
      user_rating: user.elo,
      question_rating: question.elo
    )

    answer = nil
    participant_finished = false

    ActiveRecord::Base.transaction do
      answer = participant.challenge_answers.create!(
        challenge_question: challenge_question,
        value: result.display_value,
        response: result.response,
        correct: result.correct,
        duration_ms: duration_ms,
        points: points
      )

      participant_finished = participant.challenge_answers.reload.size >= challenge.question_count
      participant.update!(
        score: participant.score + points,
        correct_count: participant.correct_count + (result.correct ? 1 : 0),
        total_ms: participant.total_ms + duration_ms,
        xp_earned: participant.xp_earned + xp_earned,
        question_started_at: nil,
        finished_at: participant_finished ? Time.current : nil
      )

      Xp.award!(user, amount: xp_earned, reason: "challenge_answer", source: answer)
      Streaks.record(user)
      user.save!
    end

    settle(challenge)

    Outcome.new(
      answer: answer,
      result: result,
      points: points,
      xp_earned: xp_earned,
      participant_finished: participant_finished
    )
  end

  # Ends the match when there is nothing left to wait for: both players done, or
  # the shared clock run out. Called on every read of a live match, so the
  # result appears without anyone having to press anything.
  def settle(challenge)
    return false unless challenge.active?

    challenge.participants.reload
    return false unless challenge.out_of_time? || challenge.participants.all?(&:done?)

    finalize!(challenge)
  end

  def finalize!(challenge)
    finished = false

    challenge.with_lock do
      next unless challenge.reload.active?

      now = Time.current
      challenge.participants.each { |participant| participant.update!(finished_at: now) unless participant.done? }
      challenge.update!(status: :finished, finished_at: now, winner_id: winner_id_for(challenge))
      finished = true
    end

    return false unless finished

    challenge.participants.each { |participant| award_result!(challenge, participant) }
    true
  end

  # Points decide it, and points already carry the clock. A dead heat on points
  # goes to whoever spent less time overall; a dead heat on both is a draw — and
  # so is a match nobody scored in, because "fastest to get everything wrong" is
  # not a win worth handing out.
  def winner_id_for(challenge)
    ranked = challenge.participants.sort_by { |participant| [ -participant.score, participant.total_ms ] }
    return nil unless ranked.size == 2
    return nil if ranked.first.score.zero?
    return nil if ranked.first.score == ranked.last.score && ranked.first.total_ms == ranked.last.total_ms

    ranked.first.user_id
  end

  def award_result!(challenge, participant)
    user = participant.user
    won = challenge.winner_id == user.id
    amount =
      if won then Xp::CHALLENGE_WIN_BONUS
      elsif challenge.draw? then Xp::CHALLENGE_DRAW_BONUS
      else Xp::CHALLENGE_PLAY_BONUS
      end

    reason = won ? "challenge_won" : (challenge.draw? ? "challenge_drawn" : "challenge_played")

    ActiveRecord::Base.transaction do
      Xp.award!(user, amount: amount, reason: reason, source: challenge)
      user.save!
      participant.update!(xp_earned: participant.xp_earned + amount)
    end

    Badges.check!(user, { type: :challenge_finished, won: won, challenge: challenge })
  end

  # Server-side, always: the speed bonus is worth cheating for, so the client is
  # never asked how long it took. A player with no stamp (a match settled out
  # from under them, a hand-rolled request) forfeits the bonus rather than
  # collecting it.
  def elapsed_ms(participant)
    return participant.challenge.seconds_per_question * 1000 if participant.question_started_at.nil?

    (participant.seconds_on_current_question * 1000).round
  end
end
