class FreeTextGrading < ApplicationRecord
  belongs_to :question

  validates :answer_hash, presence: true, uniqueness: { scope: :question_id }
  validates :verdict, presence: true, inclusion: { in: %w[correct partial incorrect] }
end
