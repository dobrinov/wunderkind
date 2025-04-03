class Question < ApplicationRecord
  belongs_to :questionable, polymorphic: true
  validates :minimum_age, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
