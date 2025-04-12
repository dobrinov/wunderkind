class Question < ApplicationRecord
  has_many :assignment_questions, dependent: :destroy
  has_many :assignments, through: :assignment_questions
  has_many :possible_answers, dependent: :destroy
end
