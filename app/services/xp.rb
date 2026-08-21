# XP awards. Correct answers pay more the harder the question is relative to the
# student (via the Elo expected score), so grinding easy questions doesn't pay.
module Xp
  ATTEMPT_AMOUNT = 2
  SESSION_BONUS = 15

  # End-of-duel bonuses. Small next to what the answers themselves paid: the
  # duel should be worth playing for the duel, not farmable by winning one.
  CHALLENGE_WIN_BONUS = 25
  CHALLENGE_DRAW_BONUS = 15
  # Everyone who finishes gets something. Losing a close race and getting
  # nothing is how a child learns to stop entering.
  CHALLENGE_PLAY_BONUS = 5

  module_function

  def amount_for_answer(correct:, user_rating:, question_rating:)
    return ATTEMPT_AMOUNT unless correct

    expected = 1.0 / (1 + 10**((question_rating - user_rating) / 400.0))
    (10 + 20 * (1 - expected)).round
  end

  def award!(user, amount:, reason:, source: nil)
    user.xp_events.create!(amount: amount, reason: reason, source: source)
    user.total_xp += amount
    amount
  end
end
