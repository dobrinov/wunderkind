# The global weekly leaderboard: nickname-only, resets Monday (Sofia time).
class LeaderboardsController < AuthenticatedController
  TOP_LIMIT = 50

  def show
    @entries = Leaderboards.global
    @my_entry = @entries.find { |entry| entry.user == current_user }
    @entries = @entries.first(TOP_LIMIT)
  end
end
