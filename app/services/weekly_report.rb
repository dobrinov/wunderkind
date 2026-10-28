# The Monday email to a parent: how each of their children's last week went.
#
# Sent only when there is something to say. A child who answered nothing is
# left out of the email, and a parent none of whose children practised gets
# no email at all — a report that arrives every week to say „nothing" is one
# people learn to delete unread, and then the week something happened is
# deleted with them. A week of duels alone counts as nothing here, the same
# way the practice history does not count them: a duel is play, not practice.
#
# Every number is read off the services the parent's own pages read, so the
# email and the page say the same thing about the same week: PracticeHistory
# for the problems, minutes and days, PerformanceTrend for how hard the
# solved problems were, Streaks, Goals' awards, AnswerLog's list for review.
class WeeklyReport
  # Moves within this many Elo points are noise from one week to the next, not
  # a change worth a sentence.
  STEADY = 25

  Child = Struct.new(:child, :days, :previous_days, :trend, :streak, :badges, :rewards, :review_count,
                     keyword_init: true) do
    def problems = days.sum(&:count)
    def correct = days.sum(&:correct)
    def minutes = days.sum(&:minutes).round
    def active_days = days.count(&:active?)
    def active? = problems.positive?
    def previous_problems = previous_days.sum(&:count)

    def accuracy
      return nil if problems.zero?

      (correct * 100.0 / problems).round
    end

    # :harder, :easier or :steady — the difficulty of what the child got right
    # this week against last week. nil when either week has no point to compare.
    def difficulty
      before, now = trend.weeks.last(2).map(&:rating)
      return nil if before.nil? || now.nil?
      return :steady if (now - before).abs < STEADY

      now > before ? :harder : :easier
    end

    def band = RatingBand.new(child.elo)
  end

  attr_reader :parent, :week_start, :children

  # The last full week, Monday to Sunday, before `today`'s.
  def self.last_week_start(today = Time.zone.today)
    today.beginning_of_week - 7
  end

  # Parents who can be sent one: they want it, have an address someone has
  # shown is theirs (a report about a child must not go to an address typed
  # at sign-up and never confirmed), and have not had this week's yet.
  def self.recipients(week_start)
    User.parent.where(weekly_report: true).where.not(email: nil).where.not(verified_at: nil).
      where("weekly_report_sent_on IS NULL OR weekly_report_sent_on < ?", week_start)
  end

  # Sends one parent's report for the week, if it has anything in it, and
  # remembers the week either way: a quiet week is decided, and asking again
  # would only decide it again. Returns whether an email went.
  def self.deliver(parent, week_start:)
    report = new(parent, week_start: week_start)
    ParentMailer.weekly_report(parent, week_start).deliver_now if report.any?
    parent.update_column(:weekly_report_sent_on, week_start)
    report.any?
  end

  def initialize(parent, week_start:)
    @parent = parent
    @week_start = week_start
    @children = parent.children.order(:name).map { |child| for_child(child) }.select(&:active?)
  end

  def week_end = week_start + 6
  def any? = children.any?

  # „19–25 октомври", „28 септември – 4 октомври". Bulgarian writes a month in
  # lower case mid-sentence, which the locale's month names do not.
  def dates_label
    month = ->(date) { name = I18n.t("date.month_names")[date.month]; I18n.locale == :bg ? name.downcase : name }
    if week_start.month == week_end.month
      "#{week_start.day}–#{week_end.day} #{month.(week_end)}"
    else
      "#{week_start.day} #{month.(week_start)} – #{week_end.day} #{month.(week_end)}"
    end
  end

  private

  def for_child(child)
    # Pays out anything the week completed before the email says what was
    # earned — see Goals.refresh!; idempotent.
    Goals.refresh!(child)
    history = PracticeHistory.new(child, weeks: 2, today: week_end)
    range = week_start.beginning_of_day..week_end.end_of_day

    Child.new(
      child: child,
      days: history.days.select { |day| day.date.between?(week_start, week_end) },
      previous_days: history.days.select { |day| day.date < week_start },
      trend: PerformanceTrend.new(child, weeks: 2, today: week_end),
      streak: Streaks.current(child, on: week_end),
      badges: child.badge_awards.where(created_at: range).filter_map { |award| Badges.find(award.badge_key) },
      rewards: GoalAward.joins(:goal).where(goals: { child_id: child.id }, earned_at: range).order(:earned_at).to_a,
      review_count: AnswerLog.wrong(child).count
    )
  end
end
