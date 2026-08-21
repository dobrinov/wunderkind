class ChallengeQuestion < ApplicationRecord
  belongs_to :challenge
  belongs_to :question
  has_many :challenge_answers, dependent: :destroy
end
