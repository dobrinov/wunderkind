# The global weekly leaderboard: nickname-only, resets Monday (Sofia time).
class LeaderboardsController < AuthenticatedController
  TOP_LIMIT = 50

  def show
    week_start = Time.use_zone("Europe/Sofia") { Time.zone.now.beginning_of_week }

    eligible = User.student.where.not(nickname: [ nil, "" ])
    @entries = Leaderboards.weekly_xp(eligible.to_a, from: week_start)
    @my_entry = @entries.find { |entry| entry.user == current_user }
    @entries = @entries.first(TOP_LIMIT)
  end
end
