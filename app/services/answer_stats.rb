# Day by day, how the bank is landing on the people answering it: how many
# problems were answered, what share of the answers were wrong, and what share
# were „не съм го учил". Drawn for a student on their own /stats page, for a
# parent on their child's page and for the admin on /overseer/stats — the same
# charts in all three, the stance the home-page cards already take. Clicking a
# day opens AnswerStats.misses for it.
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
  NOT_PENDING = "user_answers.response->>'verdict' IS DISTINCT FROM 'pending_review'".freeze

  Day = Struct.new(:date, :solved, :correct, :wrong, :skipped, :duration_ms, keyword_init: true) do
    def total = solved + skipped
    # Minutes spent on the answered problems — the seconds spent deciding you
    # were never taught something are not practice, as in PracticeHistory.
    def minutes = duration_ms.to_i / 60_000.0
    def any? = total.positive?
    def wrong_rate = any? ? (wrong * 100.0 / total).round(1) : nil
    def skipped_rate = any? ? (skipped * 100.0 / total).round(1) : nil
  end

  attr_reader :days, :user, :user_ids

  # The range a page asked for, if it is one on offer.
  def self.range(param) = param.to_i.presence_in(RANGES) || RANGES.first

  # A day out of a URL, or nil for anything that is not one — a bookmarked or
  # fiddled link is not worth an error page.
  def self.date(param)
    Date.iso8601(param.to_s)
  rescue Date::Error
    nil
  end

  # A day's answers that went wrong or were skipped — what a click on that day
  # opens. Every answer given that day, not the latest per question the way
  # AnswerLog reads them: this is a record of the day, and a problem got wrong
  # that morning and right that afternoon was still got wrong that morning.
  def self.misses(user, date)
    UserAnswer.
      where(user: user, created_at: date.all_day).
      where("user_answers.skipped OR (NOT user_answers.correct AND #{NOT_PENDING})").
      includes(assignment_question: { question: :topics }).
      order(:created_at)
  end

  # `user_ids` draws a set of users instead of one — a family, on the admin
  # page; an empty set draws nobody, not everybody.
  def initialize(days: RANGES.first, user: nil, user_ids: nil, today: Time.zone.today)
    @user = user
    @user_ids = user_ids
    first = today - (days - 1)
    counts = tally(first.beginning_of_day..today.end_of_day)

    @days = (first..today).map do |date|
      solved, correct, wrong, skipped, duration_ms = counts.fetch(date, [ 0, 0, 0, 0, 0 ])
      Day.new(date:, solved:, correct:, wrong:, skipped:, duration_ms:)
    end
  end

  def enough? = days.count(&:any?) >= 2
  def total_solved = days.sum(&:solved)
  def total_skipped = days.sum(&:skipped)
  def total_minutes = days.sum(&:minutes).round
  def active_days = days.count(&:any?)

  # Days that carry a measured duration — fewer than the active days wherever
  # answers predate the duration_ms column, as in PracticeHistory.
  def timed_days = days.count { |day| day.minutes.positive? }

  def average_minutes
    timed_days.zero? ? nil : [ (days.sum(&:minutes) / timed_days).round, 1 ].max
  end
  def max_total = days.map(&:total).max.to_i

  # Of the answered problems, the share got right — the history card's
  # „точни", which this card took over.
  def accuracy
    total_solved.zero? ? nil : (days.sum(&:correct) * 100.0 / total_solved).round
  end

  def wrong_rate = rate(:wrong)
  def skipped_rate = rate(:skipped)

  private

  def rate(field)
    total = days.sum(&:total)
    total.zero? ? nil : (days.sum(&field) * 100.0 / total).round(1)
  end

  def tally(range)
    scope = UserAnswer.where(created_at: range)
    scope =
      if user then scope.where(user: user)
      elsif user_ids then scope.where(user_id: user_ids)
      else scope.joins(:user).where.not(users: { role: :admin })
      end

    day = Arel.sql(ApplicationRecord.local_date_sql("user_answers.created_at"))
    scope.group(day).pluck(
      day,
      Arel.sql("COUNT(*) FILTER (WHERE NOT skipped)"),
      Arel.sql("COUNT(*) FILTER (WHERE NOT skipped AND correct)"),
      Arel.sql("COUNT(*) FILTER (WHERE NOT skipped AND NOT correct AND #{NOT_PENDING})"),
      Arel.sql("COUNT(*) FILTER (WHERE skipped)"),
      Arel.sql("COALESCE(SUM(duration_ms) FILTER (WHERE NOT skipped), 0)")
    ).to_h { |date, *counts| [ date, counts ] }
  end
end
