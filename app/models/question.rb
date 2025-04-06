class Question < ApplicationRecord
  has_and_belongs_to_many :assignments
  has_many :possible_answers, dependent: :destroy
  has_many :user_answers, dependent: :destroy
end
