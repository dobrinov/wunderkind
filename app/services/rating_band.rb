# A raw Elo number is not information a child or a parent can use: nobody
# outside the app knows whether 1114 is good, or what would move it. The bands
# name the ranges so the number can be demoted to a secondary line for the
# grown-ups who do read it.
#
# They are for the grown-ups only. The scale runs from 1st grade to the
# матура, so nearly every primary-school child sits in the first two bands for
# years — and „Уверен" read by a strong eight-year-old says „average", not
# „well ahead of your class". The app knows no ages, so the band cannot say
# „for your age"; a parent can, which is why the parent's card adds the school
# grades the rating corresponds to (grade_span). A child is shown their own
# progress instead (StudentProgress), and other children's ratings not at all.
#
# The 1400 boundary is deliberately the same threshold AnswerSubmission uses for
# topic mastery, so "Отличен" is not a new number invented for the UI.
class RatingBand
  Band = Struct.new(:key, :floor, :ceiling, keyword_init: true) do
    def name = I18n.t("rating_band.#{key}")
    def top? = ceiling.nil?
  end

  BANDS = [
    Band.new(key: "novice", floor: 0, ceiling: 1000),
    Band.new(key: "confident", floor: 1000, ceiling: 1200),
    Band.new(key: "strong", floor: 1200, ceiling: 1400),
    Band.new(key: "excellent", floor: 1400, ceiling: 1600),
    Band.new(key: "competitor", floor: 1600, ceiling: nil)
  ].freeze

  # The span the marker is drawn across. Wider than the bands themselves so a
  # student at either extreme still lands inside the bar.
  SCALE_FLOOR = 800
  SCALE_CEILING = 1800

  attr_reader :rating, :band

  def initialize(rating)
    @rating = rating.to_i
    @band = BANDS.find { |candidate| candidate.top? || @rating < candidate.ceiling }
  end

  def name = band.name
  def key = band.key
  def top? = band.top?

  # The school grades whose problems sit at this rating — Curriculum's windows,
  # which overlap, so 1037 is [3, 4]. Clamped to the ladder at both ends: a
  # rating under the 1st-grade window is still 1st grade, one over the top is
  # the матура.
  def grade_span
    grades = Curriculum.grades.select { |grade| grade.range.cover?(rating) }.map(&:number)
    return grades.minmax if grades.any?

    rating < Curriculum.grades.first.floor ? [ 1, 1 ] : [ 12, 12 ]
  end

  def grades_label
    low, high = grade_span
    low == high ? I18n.t("rating_band.grade_one", grade: low) : I18n.t("rating_band.grade_range", low: low, high: high)
  end

  def next_band
    BANDS[BANDS.index(band) + 1]
  end

  def points_to_next
    return nil if top?

    band.ceiling - rating
  end

  # 0.0–1.0, for positioning the marker on the bar.
  def position
    fraction_of_scale(rating)
  end

  def self.all = BANDS

  # Where each band sits on the same 800–1800 scale the marker is placed on,
  # as a fraction of the bar.
  #
  # This exists because the two used to disagree. The bar was one continuous
  # gradient and the five names under it were five evenly-spaced flex items, so
  # a rating of 1013 put the marker at 21% while „Уверен" — the band it is
  # actually in — was centred near 30%. The dot landed to the *left* of its own
  # label and read as „not quite there yet" for a student who was comfortably
  # inside the band. Two axes drawn from different numbers can only agree by
  # accident; now there is one.
  Segment = Struct.new(:band, :start, :finish, keyword_init: true) do
    def width = finish - start
    def name = band.name
    def key = band.key
  end

  def self.segments
    BANDS.map do |band|
      Segment.new(
        band: band,
        start: fraction_of_scale(band.floor),
        finish: fraction_of_scale(band.ceiling || SCALE_CEILING)
      )
    end
  end

  def self.fraction_of_scale(value)
    span = (SCALE_CEILING - SCALE_FLOOR).to_f

    ((value - SCALE_FLOOR) / span).clamp(0.0, 1.0)
  end

  private

  def fraction_of_scale(value) = self.class.fraction_of_scale(value)
end
