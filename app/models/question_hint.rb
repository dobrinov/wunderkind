class QuestionHint < ApplicationRecord
  belongs_to :question

  validates :ladder, presence: true

  def reviewed?
    reviewed_at.present?
  end
end
