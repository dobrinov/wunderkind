class UserAnswer < ApplicationRecord
  belongs_to :assignment_question
  belongs_to :user

  # Skipped answers ("I haven't been taught this") record a question being
  # passed over, not the student attempting it — they stay out of every count
  # meant to measure effort or ability.
  scope :attempted, -> { where(skipped: false) }

  validates :correct, inclusion: { in: [ true, false ] }
  validates :response, presence: true
  # The score treats skips as neither right nor wrong, which only holds if a
  # skip can never also be correct.
  validates :correct, exclusion: { in: [ true ] }, if: :skipped?
end
