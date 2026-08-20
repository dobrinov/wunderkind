class Homework < ApplicationRecord
  belongs_to :assigner, class_name: "User"
  belongs_to :classroom, optional: true
  has_many :homework_questions, -> { order(:position) }, dependent: :destroy, inverse_of: :homework
  has_many :questions, through: :homework_questions
  has_many :assignments, dependent: :destroy

  validates :title, presence: true
  validates :due_at, presence: true

  def students
    assignments.includes(:user).map(&:user)
  end

  def overdue?
    due_at.past?
  end

  def completion_for(student)
    assignment = assignments.find { |a| a.user_id == student.id }
    return nil if assignment.nil?

    {
      assignment: assignment,
      completed: assignment.completed_at.present?,
      on_time: assignment.completed_at.present? && assignment.completed_at <= due_at,
      correct: assignment.correct_answers.count,
      total: assignment.questions.count
    }
  end
end
