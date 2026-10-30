# One child's card on the parent's „Семейство“ page: this week's practice, the
# goals with their progress, and what is owed. That is what a parent opens the
# list to check, so it is on the list — the detail page and the child's own
# profile are a click further on, for the rarer visit.
#
# Pays out completed goals on the way, like the detail page does (see
# Goals.refresh!): a reward a parent cannot see is a reward nobody gives.
class ChildOverview
  attr_reader :child, :week, :standings, :owed, :band, :focus, :parents

  def initialize(child, today: Time.zone.today)
    @child = child
    @today = today
    Goals.refresh!(child, today: today)
    PracticeFocuses.refresh!(child)

    @week = PracticeHistory.new(child, weeks: 1, today: today).week
    @standings = Goals.standings(child, today: today)
    # A focus finished with a reward attached is owed like a goal's period.
    @owed = GoalAward.joins(:goal).where(goals: { child_id: child.id }).unused.count +
            child.practice_focuses.completed.where(reward_given_at: nil).where.not(reward: nil).count
    @focus = PracticeFocuses.current(child)
    @band = RatingBand.new(child.elo)
    @last_answer_at = child.user_answers.attempted.maximum(:created_at)
    # Named on the card only when there is more than one — „Родители: Деян,
    # Мама" — so each parent knows the other sees this child too.
    @parents = child.parents.order(ParentLink.arel_table[:created_at]).to_a
  end

  def streak = Streaks.current(child, on: @today)

  # Today, for the family page's „Днес" card: who practised and how much.
  def today = week.find { |day| day.today?(@today) }
  def practised_today? = today&.active? || false

  # A streak the child will lose at midnight unless they practise: the thing a
  # parent can still do something about this evening.
  def streak_at_risk? = !practised_today? && streak.positive?

  def focus_progress = focus && PracticeFocuses.progress(focus)

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
