# The trend that actually measures progress here, drawn on the student home page.
#
# It is deliberately *not* accuracy. `Dispatcher` holds every session near
# `TARGET_SUCCESS_RATE`, so a child's percentage correct is engineered flat by
# design — plotting it would draw a horizontal line under a child who is
# improving quickly. What moves instead is the difficulty: the questions get
# harder in order to keep the success rate where it is. So the series is the
# average Elo of the questions the student answered *correctly* in each week.
#
# The Elo used is the question's rating today rather than the one it carried
# when the answer was given — nothing records that. A published question's Elo
# moves by a handful of points against thousands of answers, so the curve this
# produces is the student's, not the bank's drift.
class PerformanceTrend
  WEEKS = PracticeHistory::WEEKS

  # Head- and foot-room around the plotted values, so the line never runs along
  # the edge of its own frame.
  PADDING = 40
  # A flat run of weeks would otherwise be magnified into a mountain range by
  # auto-scaling. Below this span the scale opens up around the midpoint instead.
  MIN_SPAN = 200
  # Scale ends snap to this, so the same student sees the same frame week to week.
  STEP = 50

  Week = Struct.new(:starts_on, :rating, :answers, :correct, keyword_init: true) do
    def solved? = rating.present?

    def accuracy
      return nil if answers.zero?

      (correct * 100.0 / answers).round
    end
  end

  attr_reader :weeks

  def initialize(user, weeks: WEEKS, today: Time.zone.today)
    first = (today - (weeks * 7 - 1)).beginning_of_week
    tallies = tally(user, first)

    @weeks = (0...weeks).map do |index|
      starts_on = first + (index * 7)
      elos, answers, correct = tallies.fetch(starts_on, [ [], 0, 0 ])
      Week.new(
        starts_on: starts_on,
        rating: elos.any? ? (elos.sum / elos.size.to_f).round : nil,
        answers: answers,
        correct: correct
      )
    end
  end

  # The weeks that carry a point. A week the student sat out is a gap in the
  # line, not a zero — nobody's ability dropped to nothing because it was half term.
  def points = weeks.select(&:solved?)

  # One point is a dot, not a trend.
  def enough? = points.size >= 2

  def current = points.last&.rating
  def best = points.map(&:rating).max
  def delta = enough? ? points.last.rating - points.first.rating : nil

  # [floor, ceiling] of the y axis, in Elo.
  def scale
    @scale ||= begin
      values = points.map(&:rating)
      low = values.min - PADDING
      high = values.max + PADDING

      if high - low < MIN_SPAN
        middle = (high + low) / 2.0
        low = middle - MIN_SPAN / 2.0
        high = middle + MIN_SPAN / 2.0
      end

      [ (low / STEP.to_f).floor * STEP, (high / STEP.to_f).ceil * STEP ]
    end
  end

  # 0.0 at the bottom of the frame, 1.0 at the top.
  def y_for(rating)
    low, high = scale

    ((rating - low) / (high - low).to_f).clamp(0.0, 1.0)
  end

  # 0.0 at the left edge, 1.0 at the right.
  def x_for(index)
    return 0.5 if weeks.size < 2

    index / (weeks.size - 1).to_f
  end

  # The gridlines are the rating bands rather than round numbers, because a
  # child cannot read 1350 but can read „оттук нагоре е Силен“. Only the
  # boundaries that fall inside the frame are drawn.
  def band_lines
    low, high = scale

    RatingBand::BANDS.reject(&:top?).filter_map do |band|
      next unless band.ceiling > low && band.ceiling < high

      [ band.ceiling, RatingBand.new(band.ceiling).name ]
    end
  end

  private

  # One pass over the window: correctness decides whether an answer contributes
  # a difficulty, the count of attempts is what the accuracy in the tooltip is
  # measured against. Skips are neither.
  def tally(user, from)
    user.user_answers.
      attempted.
      joins(assignment_question: :question).
      where("user_answers.created_at >= ?", from.beginning_of_day).
      pluck("user_answers.created_at", "user_answers.correct", "questions.elo").
      each_with_object({}) do |(created_at, correct, elo), acc|
        week = created_at.in_time_zone.to_date.beginning_of_week
        bucket = (acc[week] ||= [ [], 0, 0 ])
        bucket[1] += 1
        next unless correct

        bucket[0] << elo
        bucket[2] += 1
      end
  end
end
