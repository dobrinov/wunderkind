# What a child is shown about their own level: how far they have come, and how
# close the next step is.
#
# Not RatingBand, which places them on one scale for the whole of school —
# see there for why that discourages exactly the children doing well. Both
# halves here only ever compare the student with themselves:
#
#   gain  — how much harder the problems they get right are now than a month
#           ago, read off PerformanceTrend (the same weekly series the chart
#           draws), so the card and the chart cannot disagree. Positive or nil:
#           a dip is real but it is not news a child needs as a number — the
#           card says something true and kind instead.
#   step  — the rating cut into STEP-point steps, so the next one is always a
#           few good answers away rather than a band two hundred points off.
#           The steps carry no names and no numbers, so there is nothing to be
#           demoted from.
class StudentProgress
  STEP = 50
  # How far back „a month ago" reaches, in weeks with a solved problem.
  BASELINE_WEEKS = 4

  attr_reader :user, :trend

  def initialize(user, trend)
    @user = user
    @trend = trend
  end

  # [points, weeks] — the gain against the latest week at least BASELINE_WEEKS
  # before this one (or the earliest there is), or nil when there is no gain to
  # report.
  def gain
    solved = trend.weeks.each_with_index.select { |week, _| week.solved? }
    return nil if solved.size < 2

    latest, latest_index = solved.last
    base, base_index = solved.reverse.find { |_, index| latest_index - index >= BASELINE_WEEKS } || solved.first
    points = latest.rating - base.rating
    points.positive? ? [ points, latest_index - base_index ] : nil
  end

  # 0.0–1.0 through the current step.
  def step_fraction = (user.elo.to_i % STEP) / STEP.to_f

  def to_next_step = STEP - (user.elo.to_i % STEP)

  # Which sentence the card leads with when there is no gain to show.
  def mood
    trend.enough? && trend.direction == :down ? :harder_week : :keep_going
  end
end
