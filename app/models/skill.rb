class Skill < ApplicationRecord
  belongs_to :user
  belongs_to :topic

  validates :rating, numericality: { greater_than_or_equal_to: 0 }
end
