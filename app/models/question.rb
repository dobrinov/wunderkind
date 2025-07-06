class Question < ApplicationRecord
  has_many :assignment_questions, dependent: :destroy
  has_many :assignments, through: :assignment_questions
  has_many :possible_answers, dependent: :destroy
  has_many :user_answers, through: :assignment_questions
  belongs_to :question_attachment, optional: true

  accepts_nested_attributes_for :possible_answers, allow_destroy: true, reject_if: :all_blank

  validates :text, presence: true
  validates :answer, presence: true
end
