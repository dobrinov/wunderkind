class Question < ApplicationRecord
  has_many :assignment_questions, dependent: :destroy
  has_many :assignments, through: :assignment_questions
  has_many :possible_answers, dependent: :destroy
  has_many :user_answers, through: :assignment_questions
  has_and_belongs_to_many :topics
  belongs_to :attachable, polymorphic: true, optional: true

  accepts_nested_attributes_for :possible_answers, allow_destroy: true, reject_if: :all_blank

  validates :text, presence: true
  validates :answer, presence: true

  def attachable_is_image?
    return false if attachable.nil?

    attachable.is_a?(QuestionImage)
  end

  def attachable_is_script?
    return false if attachable.nil?

    attachable.is_a?(QuestionScript)
  end
end
