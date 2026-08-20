class PossibleAnswer < ApplicationRecord
  belongs_to :question

  validates :value, presence: true
end
