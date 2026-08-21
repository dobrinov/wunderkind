class ChallengeAnswer < ApplicationRecord
  belongs_to :challenge_participant
  belongs_to :challenge_question

  validates :correct, inclusion: { in: [ true, false ] }
end
