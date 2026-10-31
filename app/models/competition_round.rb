# One date of an edition — a regional and a national round are two. A date
# not yet published is `approximate`, set from last year's, and says „около"
# wherever it is shown.
class CompetitionRound < ApplicationRecord
  belongs_to :edition, class_name: "CompetitionEdition", foreign_key: :competition_edition_id, touch: true

  validates :date, presence: true
end
