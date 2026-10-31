# A competition or exam on the calendar — see Competitions, which is how the
# rest of the app reads these. Edited at /overseer/competitions.
class Competition < ApplicationRecord
  has_many :editions, -> { order(:year) }, class_name: "CompetitionEdition", dependent: :destroy

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/ }
  validates :kind, inclusion: { in: Competitions::KINDS }
  validates :style, inclusion: { in: Competitions::STYLES }
  validates :organizer, presence: true
  validates :grade_min, :grade_max, inclusion: { in: 1..12 }
  validate :texts_in_both_languages

  def to_param = slug

  private

  def texts_in_both_languages
    { name: name, description: description, format: format }.each do |field, text|
      errors.add(field, :blank) if text.to_h.values_at("bg", "en").any?(&:blank?)
    end
  end
end
