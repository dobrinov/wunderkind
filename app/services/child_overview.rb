# One child's card on the parent's „Моите деца“ list: this week's practice, the
# goals with their progress, and what is owed. That is what a parent opens the
# list to check, so it is on the list — the detail page and the child's own
# profile are a click further on, for the rarer visit.
#
# Pays out completed goals on the way, like the detail page does (see
# Goals.refresh!): a reward a parent cannot see is a reward nobody gives.
class ChildOverview
  attr_reader :child, :week, :standings, :owed, :band

  def initialize(child, today: Time.zone.today)
    @child = child
    @today = today
    Goals.refresh!(child, today: today)

    @week = PracticeHistory.new(child, weeks: 1, today: today).week
    @standings = Goals.standings(child, today: today)
    @owed = GoalAward.joins(:goal).where(goals: { child_id: child.id }).unused.count
    @band = RatingBand.new(child.elo)
    @last_answer_at = child.user_answers.attempted.maximum(:created_at)
  end

  def streak = Streaks.current(child, on: @today)

  def problems = week.sum(&:count)
  def minutes = week.sum(&:minutes).round
  def active_days = week.count(&:active?)

  def accuracy
    return nil if problems.zero?

    (week.sum(&:correct) * 100.0 / problems).round
  end

  # Days since the child last answered anything, or nil if they never have.
  def days_since_practice
    return nil unless @last_answer_at

    (@today - @last_answer_at.in_time_zone.to_date).to_i
  end
end
