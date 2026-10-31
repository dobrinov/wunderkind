# The Sunday-evening email to a parent: how each of their children's week went.
# One email per parent, every child in it — a family of three gets one email,
# not three.
#
# Sunday evening rather than Monday morning: it lands while the family can
# still talk about the week and plan the next one, and the one suggestion per
# child (a focus topic, a small goal) is something to do *this* coming week.
# The week is Monday to Sunday, read when the email is built — practice later
# that Sunday evening is in no report, the price of sending before the week
# is quite over.
#
# Sent only when there is something to say. A child who answered nothing is
# not given a section of numbers, only a short line when a sibling did
# practise (`quiet_children`), and a parent none of whose children practised
# gets no email at all — a report that arrives every week to say „nothing" is one
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

  # A week counts as „quieter" only against a last week of at least this many
  # problems, so 3 → 1 is not announced as a slump.
  QUIETER_FROM = 10

  # The one idea a section ends on, at most: what a parent could do this
  # coming week, with the place to do it.
  Suggestion = Struct.new(:kind, :topic, keyword_init: true)

  Child = Struct.new(:child, :days, :previous_days, :trend, :streak, :badges, :rewards, :review_count,
                     :best_before, :suggestion, keyword_init: true) do
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

    # :best — more problems than in any earlier week the child ever had, and
    # there was an earlier week to beat; :quieter — under half of a last week
    # that was worth comparing with. nil otherwise: most weeks deserve no label.
    def label
      return :best if best_before.to_i.positive? && problems > best_before
      return :quieter if previous_problems >= QUIETER_FROM && problems * 2 < previous_problems

      nil
    end

    # Weeks in a row, ending this one, in which the problems solved were harder
    # than the week before (PerformanceTrend). 0 unless this week rose.
    def harder_weeks
      ratings = trend.weeks.map(&:rating)
      count = 0
      ratings.each_cons(2).reverse_each do |before, now|
        break unless before && now && now > before

        count += 1
      end
      count
    end
  end

  # A child with nothing this week, named only beside a sibling who practised.
  Quiet = Struct.new(:child, :days_since, keyword_init: true)

  # A reward the family has not given yet, goal or focus: the one thing in the
  # email a parent must act on, so it goes first.
  Owed = Struct.new(:child, :reward, keyword_init: true)

  attr_reader :parent, :week_start, :children, :quiet_children, :owed

  # The week a run on `today` reports: on a Sunday the week ending today, on
  # any other day (a run that was missed and is made up) the last full one.
  def self.week_start_for(today = Time.zone.today)
    today.sunday? ? today.beginning_of_week : today.beginning_of_week - 7
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
    kids = parent.children.where(role: :student).order(:name).to_a
    entries = kids.map { |child| for_child(child) }
    @children = entries.select(&:active?)
    @quiet_children = @children.any? ? entries.reject(&:active?).map { |entry| quiet(entry.child) } : []
    @owed = kids.flat_map { |child| owed_for(child) }
  end

  def total_problems = children.sum(&:problems)
  def total_days = children.sum(&:active_days)

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
      trend: PerformanceTrend.new(child, weeks: 9, today: week_end),
      streak: Streaks.current(child, on: week_end),
      # The coins of the week, named as the child sees them („Злато · Научих я!").
      badges: child.badge_awards.where(created_at: range).order(:created_at).filter_map { |award|
        (track = Coins.find(award.badge_key)) &&
          "#{I18n.t("coins.materials.#{track.material(award.rung)}")} · #{I18n.t("coins.tracks.#{track.key}.name")}"
      },
      rewards: GoalAward.joins(:goal).where(goals: { child_id: child.id }, earned_at: range).order(:earned_at).to_a,
      review_count: AnswerLog.wrong(child).count,
      best_before: best_week_before(child),
      suggestion: suggestion_for(child, history)
    )
  end

  # The most problems in any one earlier calendar week (Sofia's, Monday
  # first), counted the way PracticeHistory counts: answers, not skips.
  def best_week_before(child)
    child.user_answers.attempted.where(created_at: ...week_start.beginning_of_day)
         .group(Arel.sql("date_trunc('week', user_answers.created_at AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.tzinfo.identifier}')"))
         .count.values.max
  end

  # A slipping week with no goal running asks for a small goal; otherwise the
  # weakest topic, when no focus is set yet. Nothing when a parent already
  # has both in hand — the email does not nag about what is being done.
  def suggestion_for(child, history)
    this_week = history.days.select { |day| day.date.between?(week_start, week_end) }
    last_week = history.days.select { |day| day.date < week_start }
    active = this_week.count(&:active?)
    slipping = active.positive? && active < 3 && last_week.count(&:active?) > active
    if slipping && Goal.active.where(child: child).none?
      return Suggestion.new(kind: :goal)
    end
    return nil if PracticeFocuses.current(child)

    weakest = TopicPractice.weakest(child).first
    weakest && Suggestion.new(kind: :focus, topic: weakest.topic)
  end

  def quiet(child)
    last = child.user_answers.attempted.where(created_at: ..week_end.end_of_day).maximum(:created_at)
    Quiet.new(child: child, days_since: last && (week_end - last.in_time_zone.to_date).to_i)
  end

  def owed_for(child)
    goals = GoalAward.joins(:goal).where(goals: { child_id: child.id }).unused.order(:earned_at).map(&:reward)
    focuses = child.practice_focuses.completed.where(reward_given_at: nil).where.not(reward: nil).pluck(:reward)
    (goals + focuses).compact_blank.map { |reward| Owed.new(child: child, reward: reward) }
  end
end
