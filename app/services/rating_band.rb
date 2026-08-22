# A raw Elo number is not information a child or a parent can use: nobody
# outside the app knows whether 1114 is good, or what would move it. The bands
# name the ranges so the number can be demoted to a secondary line for the
# grown-ups who do read it.
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

  def next_band
    BANDS[BANDS.index(band) + 1]
  end

  def points_to_next
    return nil if top?

    band.ceiling - rating
  end

  # 0.0–1.0, for positioning the marker on the gradient bar.
  def position
    span = (SCALE_CEILING - SCALE_FLOOR).to_f
    ((rating - SCALE_FLOOR) / span).clamp(0.0, 1.0)
  end

  def self.all = BANDS
end
