# Measuring a goal, and paying out when it is met.
#
# Nothing about progress is stored. A goal is a question asked of
# `user_answers` — "how many days last week did this child practise fifteen
# minutes" — and it is asked fresh every time anybody looks, exactly the way
# PracticeHistory is. The only rows written are the awards, and those are
# written because a promise that was kept has to survive the goal being edited
# afterwards.
#
# Paying out happens on read rather than on answer. The moment a child finishes
# a session they land back on the calendar, which is where the card saying they
# have earned something lives — a better moment for it than the feedback screen
# of whichever problem happened to tip the total, and it keeps AnswerSubmission
# out of this entirely. `refresh!` is idempotent: the unique index on
# (goal_id, period_start) is what makes a second look cost nothing.
module Goals
  # How far back a refresh will look for periods nobody ever collected. A
  # parent who has not opened the app in two months should still find the weeks
  # their child earned; a goal running since spring should not make every page
  # view walk the year.
  BACKFILL_DAYS = 70

  Progress = Struct.new(:done, :target, keyword_init: true) do
    def complete? = done >= target
    def fraction = target.positive? ? [ done.to_f / target, 1.0 ].min : 0.0
    def percent = (fraction * 100).round
  end

  # One query's worth of a child's daily numbers, so a refresh that has to
  # evaluate ten periods still only asks once. Mirrors PracticeHistory#tally,
  # and groups in Ruby for the same reason: the window is small, and a DATE()
  # cast would have to carry the app's zone into SQL to agree with Time.zone.
  class Tally
    Day = Struct.new(:minutes, :problems, :correct)

    def initialize(child, from, to)
      @days = child.user_answers.
        attempted.
        where(created_at: from.beginning_of_day..to.end_of_day).
        pluck(:created_at, :correct, :duration_ms).
        each_with_object({}) do |(created_at, correct, duration_ms), acc|
          day = acc[created_at.in_time_zone.to_date] ||= Day.new(0.0, 0, 0)
          day.minutes += duration_ms.to_i / 60_000.0
          day.problems += 1
          day.correct += 1 if correct
        end
    end

    def on(date) = @days[date] || Day.new(0.0, 0, 0)
  end

  module_function

  # The periods of this goal that have begun, newest first — the current one
  # and however many finished ones are still inside BACKFILL_DAYS.
  def periods(goal, today: Time.zone.today)
    return [] if goal.starts_on > today

    case goal.period
    when "once" then [ [ goal.starts_on, goal.ends_on ] ]
    else walk_periods(goal, today)
    end
  end

  def current_period(goal, today: Time.zone.today)
    periods(goal, today: today).find { |(_, finish)| finish >= today } || periods(goal, today: today).first
  end

  def period_length(goal)
    case goal.period
    when "week" then 7
    when "month" then 31
    else goal.ends_on && goal.starts_on ? (goal.ends_on - goal.starts_on).to_i + 1 : nil
    end
  end

  # How much of `period` this child has done. The three metrics differ only in
  # which number is read off a day.
  def progress(goal, period, tally)
    start, finish = period
    days = (start..finish).select { |date| date <= Time.zone.today }

    done =
      if goal.daily?
        days.count { |date| value_on(goal, tally, date) >= goal.threshold }
      else
        days.sum { |date| value_on(goal, tally, date) }
      end

    Progress.new(done: done.floor, target: goal.target)
  end

  def value_on(goal, tally, date)
    day = tally.on(date)

    case goal.metric
    when "minutes" then day.minutes
    when "problems" then day.problems
    else day.correct
    end
  end

  # Pays out every period this child has completed and not yet been paid for,
  # across all their active goals. Safe to call on any read.
  def refresh!(child, today: Time.zone.today)
    goals = Goal.active.where(child: child).to_a
    return [] if goals.empty?

    tally = Tally.new(child, today - BACKFILL_DAYS, today)

    goals.flat_map { |goal| award_completed(goal, tally, today) }
  end

  def award_completed(goal, tally, today)
    paid = goal.awards.pluck(:period_start)

    periods(goal, today: today).filter_map do |period|
      start, finish = period
      next if paid.include?(start)
      next unless progress(goal, period, tally).complete?

      create_award(goal, start, finish)
    end
  end

  # The unique index is the real guard: two tabs open on the same child would
  # otherwise both see a finished period and both pay for it.
  def create_award(goal, start, finish)
    goal.awards.create!(period_start: start, period_end: finish, reward: goal.reward, earned_at: Time.current)
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  # Everything a screen needs about one goal: the period in play and how far
  # through it the child is.
  Standing = Struct.new(:goal, :period, :progress, keyword_init: true)

  def standings(child, today: Time.zone.today)
    goals = Goal.active.where(child: child).order(:created_at).to_a
    return [] if goals.empty?

    tally = Tally.new(child, today - BACKFILL_DAYS, today)

    goals.filter_map do |goal|
      period = current_period(goal, today: today)
      next if period.nil?

      Standing.new(goal: goal, period: period, progress: progress(goal, period, tally))
    end
  end

  # Weeks start on Monday and months on the 1st — a goal's week has to be the
  # week a family talks about, not a rolling seven days from whenever the
  # parent happened to set it up.
  def walk_periods(goal, today)
    first = [ goal.starts_on, today - BACKFILL_DAYS ].max
    cursor = period_start_for(goal, first)
    result = []

    while cursor <= today
      finish = period_finish_for(goal, cursor)
      result << [ [ cursor, goal.starts_on ].max, finish ]
      cursor = finish + 1
    end

    result.reverse
  end

  def period_start_for(goal, date)
    goal.week? ? date.beginning_of_week : date.beginning_of_month
  end

  def period_finish_for(goal, start)
    goal.week? ? start.end_of_week : start.end_of_month
  end
end
