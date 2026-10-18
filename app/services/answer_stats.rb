# Day by day, how the bank is landing on the people answering it: how many
# problems were answered, what share of the answers were wrong, and what share
# were „не съм го учил". Read by the admin stats page, for everybody or for one
# user.
#
# Both shares are of *every* answer that day, skips included, so they sit on
# one scale with the correct answers and the three add up to the whole —
# „12% wrong" and „8% skipped" mean 80% right, with no second denominator to
# keep in your head. A free-text answer waiting for a grader is neither right
# nor wrong (UserAnswer#pending_review?), so it counts towards the day's total
# and nowhere else.
#
# Admins' own answers are left out of the everybody view for the reason
# Analytics leaves them out: the owner is the heaviest user of this app, and
# their testing would be most of the chart.
class AnswerStats
  RANGES = [ 30, 90, 365 ].freeze

  Day = Struct.new(:date, :solved, :wrong, :skipped, keyword_init: true) do
    def total = solved + skipped
    def any? = total.positive?
    def wrong_rate = any? ? (wrong * 100.0 / total).round(1) : nil
    def skipped_rate = any? ? (skipped * 100.0 / total).round(1) : nil
  end

  attr_reader :days, :user

  def initialize(days: RANGES.first, user: nil, today: Time.zone.today)
    @user = user
    first = today - (days - 1)
    counts = tally(first.beginning_of_day..today.end_of_day)

    @days = (first..today).map do |date|
      solved, wrong, skipped = counts.fetch(date, [ 0, 0, 0 ])
      Day.new(date: date, solved: solved, wrong: wrong, skipped: skipped)
    end
  end

  def enough? = days.count(&:any?) >= 2
  def total_solved = days.sum(&:solved)
  def max_solved = days.map(&:solved).max.to_i

  def wrong_rate = rate(:wrong)
  def skipped_rate = rate(:skipped)

  private

  def rate(field)
    total = days.sum(&:total)
    total.zero? ? nil : (days.sum(&field) * 100.0 / total).round(1)
  end

  def tally(range)
    scope = UserAnswer.where(created_at: range)
    scope = user ? scope.where(user: user) : scope.joins(:user).where.not(users: { role: :admin })

    scope.group(Arel.sql("DATE(user_answers.created_at)")).pluck(
      Arel.sql("DATE(user_answers.created_at)"),
      Arel.sql("COUNT(*) FILTER (WHERE NOT skipped)"),
      Arel.sql("COUNT(*) FILTER (WHERE NOT skipped AND NOT correct AND response->>'verdict' IS DISTINCT FROM 'pending_review')"),
      Arel.sql("COUNT(*) FILTER (WHERE skipped)")
    ).to_h { |date, *counts| [ date, counts ] }
  end
end
