class Assignment < ApplicationRecord
  belongs_to :user
  has_many :assignment_questions, dependent: :destroy
  has_many :questions, through: :assignment_questions
  has_many :user_answers, through: :assignment_questions

  def unanswered_questions
    assignment_questions.where.missing(:user_answer)
  end

  def answered_questions
    assignment_questions.joins(:user_answer)
  end

  def correct_answers
    answered_questions.joins(:question, :user_answer).where("questions.answer = user_answers.value")
  end
end
