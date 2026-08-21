# Nine weeks of practice, one row per weekday, in one query — the contribution
# strip that replaced the month grid on the student home page, plus the week of
# dots next to the streak. A month of aspect-square cells cost ~1160px to say
# "you practised on the 20th"; this says the same thing and more in ~130px.
#
# Skips stay out of it: UserAnswer.attempted is what measures effort.
class PracticeHistory
  WEEKS = 9

  Day = Struct.new(:date, :count, :correct, keyword_init: true) do
    def active? = count.positive?
    def today?(today = Time.zone.today) = date == today
    def future?(today = Time.zone.today) = date > today

    # Four steps, because the strip has four shades. Not a percentile: a child
    # should see the same colour for the same amount of work every week.
    def level
      case count
      when 0 then 0
      when 1..4 then 1
      when 5..9 then 2
      else 3
      end
    end
  end

  attr_reader :days

  def initialize(user, weeks: WEEKS, today: Time.zone.today)
    @today = today
    # Start on a Monday so each column of the strip is one calendar week.
    first = (today - (weeks * 7 - 1)).beginning_of_week
    counts = tally(user, first)

    @days = (first..today.end_of_week).map do |date|
      count, correct = counts.fetch(date, [ 0, 0 ])
      Day.new(date: date, count: count, correct: correct)
    end
  end

  # Columns of seven, oldest first — the strip renders one element per column so
  # the month labels above it can line up.
  def weeks
    days.each_slice(7).to_a
  end

  # This calendar week, Monday to Sunday, for the streak dots. Days still to
  # come are in it and answer #future? — the row is a week, not a countdown.
  def week
    days.select { |day| day.date.between?(@today.beginning_of_week, @today.end_of_week) }
  end

  def total_answers = days.sum(&:count)
  def total_correct = days.sum(&:correct)
  def active_days = days.count(&:active?)

  def accuracy
    return nil if total_answers.zero?

    (total_correct * 100.0 / total_answers).round
  end

  private

  # Grouped in Ruby rather than SQL: the window is bounded, it is one column of
  # one user's rows, and a DATE() cast would have to carry the app's zone into
  # the query to agree with Time.zone.today.
  def tally(user, from)
    user.user_answers.
      attempted.
      where(created_at: from.beginning_of_day..).
      pluck(:created_at, :correct).
      each_with_object({}) do |(created_at, correct), acc|
        date = created_at.in_time_zone.to_date
        bucket = (acc[date] ||= [ 0, 0 ])
        bucket[0] += 1
        bucket[1] += 1 if correct
      end
  end
end
