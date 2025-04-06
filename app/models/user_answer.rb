class UserAnswer < ApplicationRecord
  belongs_to :assignment
  belongs_to :question

  validates :value, presence: true
end
