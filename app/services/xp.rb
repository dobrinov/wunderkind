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

  # A mistake put right in a mistakes session. Straight after reading the
  # worked answer it is recall, and paid half: in the family field test a
  # child earned 164 XP in 96 seconds redoing ten problems he had just been
  # shown, and the family league ranked it. Days later it is the thing spaced
  # practice is for — the knowledge stayed — and pays a bonus on top.
  RECALL_AFTER_DAYS = 3
  RECALL_BONUS = 1.5

  def for_mistake_redone(amount, mistake_at)
    return amount if mistake_at.nil?
    return (amount / 2.0).ceil if mistake_at.to_date == Time.zone.today
    return (amount * RECALL_BONUS).round if mistake_at <= RECALL_AFTER_DAYS.days.ago

    amount
  end

  def award!(user, amount:, reason:, source: nil)
    user.xp_events.create!(amount: amount, reason: reason, source: source)
    user.total_xp += amount
    amount
  end
end
