class AddLobbyToChallenges < ActiveRecord::Migration[8.0]
  # The duel used to begin the instant a second player arrived, which gave the
  # one who had been waiting no moment to put their hands on the keyboard. Now
  # a filled lobby is its own phase: both players ready up, a countdown runs,
  # and only then does the clock start.
  #
  #   paired_at  — when the lobby filled, so one nobody readies in can expire
  #   starts_at  — the countdown's deadline, set by the last ready press and
  #                used as started_at so the match clock is the same length
  #                for both players whoever's poll flips it
  #   ready_at   — each player's „Готов съм"
  def change
    add_column :challenges, :paired_at, :datetime
    add_column :challenges, :starts_at, :datetime
    add_column :challenge_participants, :ready_at, :datetime
  end
end
