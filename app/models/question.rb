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
  # Who proposed the problem through the suggestion flow — credited wherever
  # the question is asked, unlike an author, who expects no byline.
  belongs_to :suggested_by, class_name: "User", optional: true
  has_one :hint, class_name: "QuestionHint", dependent: :destroy
  has_many :reports, class_name: "QuestionReport", dependent: :destroy
  has_many :revisions, class_name: "QuestionRevision", dependent: :delete_all

  enum :answer_type, { multiple_choice: 0, exact_value: 1, interactive: 2, free_text: 3 }
  # `retired` is the end of a question's life rather than a step before it: it
  # was published, students answered it, and it is not to be asked again. It
  # differs from `draft` in what it promises — a draft is waiting for an edit
  # and a re-import will publish it, a retired question is kept only so that
  # every answer ever given to it still has its problem to show.
  enum :status, { draft: 0, private_library: 1, in_review: 2, published: 3, retired: 4 }, default: :draft

  accepts_nested_attributes_for :possible_answers, allow_destroy: true, reject_if: :all_blank

  validates :body, presence: true
  validates :body_text, presence: true
  validates :grading, presence: true, if: -> { exact_value? || interactive? }
  validate :free_text_has_rubric
  validate :multiple_choice_has_correct_option
  # Only a body that changed is checked, so a row stored before the check
  # existed can still be retired or re-statused without being rewritten.
  validate :body_is_a_document, if: :body_changed?

  before_validation :project_body_text
  after_update :leave_unfinished_sessions, if: -> { saved_change_to_status? && status_before_last_save == "published" }

  def correct_possible_answers
    possible_answers.select(&:correct?)
  end

  def widget_type
    grading["widget"] if interactive?
  end

  def image
    attachable if attachable.is_a?(QuestionImage)
  end

  def retire!
    update!(status: :retired)
  end

  private

  # Taking a question out of circulation has to reach the sessions that were
  # already composed with it, or a daily session left open over the weekend
  # would still ask it on Monday. Only the unanswered rows go: an answered one
  # *is* the student's history, and the whole point of retiring rather than
  # deleting is that it stays. A placement is built one question at a time, so
  # the row it was waiting on is replaced by the next one its search picks; any
  # other session simply gets shorter, and is finished on the spot if this was
  # all it had left.
  def leave_unfinished_sessions
    pending = assignment_questions.left_joins(:user_answer).where(user_answers: { id: nil }).includes(:assignment)

    pending.each do |row|
      row.destroy!
      settle(row.assignment)
    end
  end

  def settle(assignment)
    return Placement.advance!(assignment) if assignment.placement? && assignment.completed_at.nil?
    return unless assignment.completed_at.nil? && assignment.complete?

    if assignment.assignment_questions.exists?
      assignment.update!(completed_at: Time.current)
    else
      assignment.destroy!
    end
  end

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

  # RichContent.render ignores what it does not know, so a malformed body could
  # never inject markup — but it would render as nothing, and a question whose
  # text silently vanished is a question a child is asked without seeing it.
  def body_is_a_document
    return if body.blank?

    errors.add(:body, :invalid) unless RichContent.valid?(body)
  end
end
