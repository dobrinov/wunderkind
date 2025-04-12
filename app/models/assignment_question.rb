class AssignmentQuestion < ApplicationRecord
  belongs_to :assignment
  belongs_to :question
  has_one :user_answer, dependent: :destroy
end
