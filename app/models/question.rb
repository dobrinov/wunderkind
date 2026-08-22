class Question < ApplicationRecord
  has_many :assignment_questions, dependent: :destroy
  has_many :assignments, through: :assignment_questions
  has_many :challenge_questions, dependent: :destroy
  has_many :challenges, through: :challenge_questions
  has_many :possible_answers, -> { order(:position) }, dependent: :destroy, inverse_of: :question
  has_many :user_answers, through: :assignment_questions
  has_and_belongs_to_many :topics
  belongs_to :attachable, polymorphic: true, optional: true
  belongs_to :author, class_name: "User", optional: true
  has_one :hint, class_name: "QuestionHint", dependent: :destroy
  has_many :reports, class_name: "QuestionReport", dependent: :destroy

  enum :answer_type, { multiple_choice: 0, exact_value: 1, interactive: 2, free_text: 3 }
  enum :status, { draft: 0, private_library: 1, in_review: 2, published: 3 }, default: :draft

  accepts_nested_attributes_for :possible_answers, allow_destroy: true, reject_if: :all_blank

  validates :body, presence: true
  validates :body_text, presence: true
  validates :grading, presence: true, if: -> { exact_value? || interactive? }
  validate :free_text_has_rubric
  validate :multiple_choice_has_correct_option

  before_validation :project_body_text

  def correct_possible_answers
    possible_answers.select(&:correct?)
  end

  def widget_type
    grading["widget"] if interactive?
  end

  def image
    attachable if attachable.is_a?(QuestionImage)
  end

  private

  def project_body_text
    self.body_text = RichContent.plain_text(body) if body.present?
  end

  def multiple_choice_has_correct_option
    return unless multiple_choice?
    return if possible_answers.reject(&:marked_for_destruction?).any? { |option| option.correct? }

    errors.add(:possible_answers, :no_correct_option)
  end

  def free_text_has_rubric
    return unless free_text?

    errors.add(:grading, :missing_rubric) if grading["rubric"].blank?
  end
end
