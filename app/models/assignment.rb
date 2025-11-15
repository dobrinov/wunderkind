class Assignment < ApplicationRecord
  belongs_to :user
  has_many :assignment_questions, dependent: :destroy
  has_many :user_answers, through: :assignment_questions
  has_many :questions, through: :assignment_questions

  def next_question
    unanswered_questions.first
  end

  def unanswered_questions
    Question.
      joins(assignment_questions: :assignment).
      left_joins(assignment_questions: :user_answer).
      where(assignment_questions: { assignments: { id: id } }).
      where(assignment_questions: { user_answers: { id: nil } })
  end

  def answered_questions
    Question.joins(assignment_questions: :user_answer).where(assignment_questions: { assignment: self })
  end

  def correct_answers
    answered_questions.where("questions.answer = user_answers.value")
  end
end
