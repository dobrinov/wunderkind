# A student saying „ще участвам" in one competition for one season. The
# competition itself is a row of config/competitions.yml, named by slug.
class CompetitionEntry < ApplicationRecord
  belongs_to :user

  validates :season, presence: true
  validates :competition_slug, uniqueness: { scope: [ :user_id, :season ] }
  validate :competition_exists

  # The upcoming events this user has entered for the season each one is in —
  # last spring's entry in the Kangaroo is not an entry in this spring's.
  def self.upcoming_for(user, today = Time.zone.today)
    entered = user.competition_entries.pluck(:competition_slug, :season)
    Competitions.upcoming(today).select { |event| entered.include?([ event.slug, event.season(today) ]) }
  end

  def competition = Competitions.find(competition_slug)

  private

  def competition_exists
    errors.add(:competition_slug, :invalid) unless competition
  end
end
