# Points for one answer in a head-to-head match.
#
# Correctness is the floor and speed is the bonus, in that order: the fastest
# wrong answer is worth nothing, and a correct answer is worth more than a
# faster one can ever be worth on its own. That ordering matters — a child who
# learns that guessing quickly pays has learned the wrong lesson from the game.
module ChallengeScoring
  CORRECT_POINTS = 100

  # The most the clock can add on top of a correct answer. Kept below
  # CORRECT_POINTS so two correct answers always beat one, however slow.
  SPEED_POINTS = 50

  module_function

  # `duration_ms` is measured server-side from when the problem was served.
  def points(correct:, duration_ms:, seconds_per_question:)
    return 0 unless correct

    limit = seconds_per_question * 1000.0
    left = 1 - (duration_ms.to_i.clamp(0, limit) / limit)

    CORRECT_POINTS + (SPEED_POINTS * left).round
  end
end
