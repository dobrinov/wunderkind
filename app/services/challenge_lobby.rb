# The phase between being paired and the clock starting.
#
# The duel used to begin the instant a second player arrived, which is fine for
# whoever pressed the button last and unfair to the one who had been waiting:
# they were already thirty seconds into a lobby, looking somewhere else, and
# the first problem was on screen with the speed bonus running. A room both
# players step into, ready up in, and watch a countdown out of costs five
# seconds and makes the start the same for both of them.
#
# There is no host and no start button, deliberately. The queue pairs
# strangers, and a stranger holding the only start button is a stranger who can
# hold you there — or wander off with you waiting on them. Both press „Готов
# съм", the last press starts the countdown, and nobody is waiting on anybody's
# goodwill. (A host button is the right shape for a room you invited a friend
# into; there is no such room yet.)
module ChallengeLobby
  module_function

  # One player's „Готов съм". The last one starts the countdown.
  #
  # Under the challenge's lock rather than the participant's: what the last
  # press decides is a property of the room, and two presses landing together
  # must not both read "the other one isn't ready yet" and leave a full room
  # that never counts down.
  def ready!(challenge, participant)
    return false unless challenge.lobby? && participant && !participant.ready?

    readied = false

    challenge.with_lock do
      # Re-checked inside the lock like every other write in the duel flow: the
      # opponent may have pressed Cancel, or the sweep may have written the
      # room off, between the test above and this line.
      next unless challenge.reload.lobby?

      participant.update!(ready_at: Time.current)
      readied = true

      next if challenge.starts_at.present?

      # Reloaded because the press that just landed was on another instance of
      # this row, and the association was read before it.
      challenge.participants.reload
      next unless challenge.everyone_ready?

      challenge.update!(starts_at: Challenge::COUNTDOWN_SECONDS.seconds.from_now)
    end

    readied
  end

  # A countdown that has run out is a match. Flipped lazily on the next read,
  # exactly like ChallengeSubmission.settle flips a match whose clock has run
  # out: there is no job, and the countdown is a number both clients work out
  # from the same server timestamp, so whoever asks first does the flip.
  #
  # `started_at` is the countdown's own deadline and not `Time.current`. The
  # match clock is then the same length for both players however late the poll
  # that happened to start it was — the alternative hands a second or two of
  # the shared clock to whichever browser was slower to ask.
  def begin!(challenge)
    return false unless challenge.lobby? && challenge.starts_at && challenge.starts_at <= Time.current

    # Both of them readied and then walked away, and the whole match clock has
    # run out too. Starting it now would mean a match that is over before its
    # first paint — a 0:00 scoreboard, a problem served onto a finished match,
    # and a 0–0 draw paying both players the draw bonus for a duel neither of
    # them was at. It is written off instead, the way an un-readied room is.
    if challenge.starts_at + challenge.time_limit_seconds <= Time.current
      challenge.update!(status: :abandoned)
      return false
    end

    started = false

    challenge.with_lock do
      next unless challenge.reload.lobby?

      challenge.update!(status: :active, started_at: challenge.starts_at)
      started = true
    end

    started
  end
end
