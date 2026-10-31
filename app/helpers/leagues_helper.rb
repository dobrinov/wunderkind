module LeaguesHelper
  # The grey line under a name in a league table: who has not practised yet,
  # or how many days of the week met their own goal — the thing a league
  # point is made of (see Leagues).
  def league_note(standing)
    return t("leagues.not_yet") unless standing.rank
    return if standing.goal_days.zero?

    t("leagues.goal_days", count: standing.goal_days)
  end
end
