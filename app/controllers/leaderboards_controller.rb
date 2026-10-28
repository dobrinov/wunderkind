# The global weekly leaderboard: nickname-only, resets Monday (Sofia time).
#
# Only players with points this week are on it, ranked among themselves — the
# same count the home page's card gives („място 1 от 2"). A list of strangers
# on „0" says nothing, and your own „7. — 0" on it reads as being singled out;
# a student with nothing yet gets a line telling them so instead of a row.
class LeaderboardsController < AuthenticatedController
  TOP_LIMIT = 50

  def show
    @entries = Leaderboards.global.select { |entry| entry.xp.positive? }
    @my_entry = @entries.find { |entry| entry.user == current_user }
    @entries = @entries.first(TOP_LIMIT)
  end
end
