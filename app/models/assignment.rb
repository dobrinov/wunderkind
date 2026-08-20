class Assignment < ApplicationRecord
  belongs_to :user
  belongs_to :homework, optional: true
  has_many :assignment_questions, -> { order(:position) }, dependent: :destroy, inverse_of: :assignment
  has_many :user_answers, through: :assignment_questions
  has_many :questions, through: :assignment_questions

  enum :kind, { practice: 0, homework: 1, daily: 2 }, default: :practice

  def next_assignment_question
    assignment_questions.left_joins(:user_answer).where(user_answers: { id: nil }).first
  end

  def next_question
    next_assignment_question&.question
  end

  def unanswered_questions
    questions.merge(assignment_questions.left_joins(:user_answer).where(user_answers: { id: nil }))
  end

  def answered_questions
    Question.joins(assignment_questions: :user_answer).where(assignment_questions: { assignment: self })
  end

  def correct_answers
    answered_questions.where(user_answers: { correct: true })
  end
end
