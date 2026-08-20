# Daily streaks: a day counts once any session activity happens. A missed single
# day can be bridged by a streak freeze, earned one per full week of streak
# (capped), so a child's long streak doesn't die to one busy day.
module Streaks
  MAX_FREEZES = 2
  FREEZE_EVERY_DAYS = 7

  module_function

  # Mutates the user's streak fields; the caller is responsible for saving.
  def record(user, on: Date.current)
    return user.current_streak if user.last_active_on == on

    if user.last_active_on == on - 1
      user.current_streak += 1
    elsif user.last_active_on == on - 2 && user.streak_freezes.positive?
      user.streak_freezes -= 1
      user.current_streak += 1
    else
      user.current_streak = 1
    end

    if user.current_streak.positive? && (user.current_streak % FREEZE_EVERY_DAYS).zero?
      user.streak_freezes = [ user.streak_freezes + 1, MAX_FREEZES ].min
    end

    user.longest_streak = [ user.longest_streak, user.current_streak ].max
    user.last_active_on = on
    user.current_streak
  end
end
