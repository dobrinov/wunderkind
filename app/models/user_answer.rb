class UserAnswer < ApplicationRecord
  belongs_to :assignment_question
  belongs_to :user

  def correct?
    value == assignment_question.question.answer
  end
end
