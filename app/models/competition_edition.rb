# One year of a competition: its rounds and, where it differs from the
# competition's usual one, that year's format. The year is the calendar year
# of its first round — СМТ 2026 is the November 2026 tournament, Кенгуру 2027
# the March 2027 one.
class CompetitionEdition < ApplicationRecord
  belongs_to :competition, touch: true
  has_many :rounds, -> { order(:date) }, class_name: "CompetitionRound", dependent: :destroy
  accepts_nested_attributes_for :rounds, allow_destroy: true, reject_if: ->(attrs) { attrs["date"].blank? }

  validates :year, numericality: { only_integer: true, in: 1980..2100 }, uniqueness: { scope: :competition_id }
end
