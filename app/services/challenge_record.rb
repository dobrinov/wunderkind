# A student's duel record, as a query over finished matches rather than
# counters on the user row — same reasoning as Leaderboards.
module ChallengeRecord
  Record = Struct.new(:played, :won, :drawn, :lost, keyword_init: true) do
    def win_rate
      return 0 if played.zero?

      (won.to_f / played * 100).round
    end
  end

  module_function

  def for(user)
    challenges = Challenge.finished.joins(:participants).where(challenge_participants: { user_id: user.id })
    played = challenges.count
    won = challenges.where(winner_id: user.id).count
    drawn = challenges.where(winner_id: nil).count

    Record.new(played: played, won: won, drawn: drawn, lost: played - won - drawn)
  end

  # Finished matches, newest first, with everything the list needs loaded.
  def history(user, limit: 10)
    Challenge.finished.
      joins(:participants).
      where(challenge_participants: { user_id: user.id }).
      includes(participants: :user).
      order(finished_at: :desc).
      limit(limit)
  end
end
