# Where a student stands this week on every board they are on — the global
# one and their leagues — for the card on the home page. The boards live
# under the duel's „Класация" tab, which is three taps from anywhere; this is
# the glance that makes them worth opening.
#
# A place is only given on a board where the student has points this week,
# and is counted among those who do: „5-ти от 300", most of whom have not
# opened the app since spring, is not a place.
class LeaderboardSummary
  Row = Struct.new(:name, :league, :place, :of, keyword_init: true)

  LEAGUES_SHOWN = 3

  attr_reader :rows

  def initialize(user)
    @user = user
    @rows = [ global_row ].compact + league_rows
  end

  def nickname_missing? = @user.nickname.blank?

  def leagues? = @rows.any?(&:league)

  private

  def global_row
    return nil if nickname_missing?

    entries = Leaderboards.global.select { |entry| entry.xp.positive? }
    mine = entries.find { |entry| entry.user == @user }
    Row.new(name: nil, place: mine&.rank, of: entries.size)
  end

  def league_rows
    return [] unless @user.may_join_leagues?

    @user.leagues.order(:name).limit(LEAGUES_SHOWN).map do |league|
      standings = Leagues.standings(league)
      mine = standings.find { |standing| standing.user == @user }
      Row.new(name: league.name, league: league, place: mine&.rank, of: standings.count(&:rank))
    end
  end
end
