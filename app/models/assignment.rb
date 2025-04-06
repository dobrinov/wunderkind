class Assignment < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :questions
  has_many :user_answers, dependent: :destroy

  def next_question
    questions.
      joins("LEFT JOIN user_answers ON questions.id = user_answers.question_id AND user_answers.assignment_id = #{id}").
      where(user_answers: { id: nil }).
      order("RANDOM()").
      first
  end

  def answered_questions
    questions.joins(:user_answers).where(user_answers: { assignment_id: id })
  end

  def correct_answers
    questions.
      joins(:user_answers).
      where("user_answers.value = questions.answer").
      where(user_answers: { assignment_id: id })
  end
end
