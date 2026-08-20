class UserAnswer < ApplicationRecord
  belongs_to :assignment_question
  belongs_to :user

  validates :correct, inclusion: { in: [ true, false ] }
  validates :response, presence: true
end
