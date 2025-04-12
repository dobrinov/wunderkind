class UserAnswer < ApplicationRecord
  belongs_to :assignment_question
  belongs_to :user
end
