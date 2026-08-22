# A problem suggested by any user — student, parent or admin. The
# form is deliberately lighter than the authoring editor: the problem is typed
# as plain text (bare fractions are promoted to math nodes exactly as problem
# files are), the answer is a number a student could type, and the topic is a
# single pick. What comes out is an ordinary Question headed for the admin
# review queue, carrying `suggested_by` so the suggester is credited wherever
# the problem is asked.
class Suggestion
  include ActiveModel::Model

  attr_accessor :text, :answer, :explanation, :topic_id, :suggested_by

  validates :text, presence: true
  validates :answer, presence: true
  validates :topic_id, presence: true
  validate :answer_is_a_value
  validate :topic_exists
  validate :problem_is_new

  def save
    return false unless valid?

    question.save!
    true
  end

  # The question the suggestion becomes. Difficulty starts at the suggester's
  # own rating — people propose problems from where they stand — and the admin
  # adjusts it in review if the guess is off.
  def question
    @question ||= Question.new(
      body: RichContent.text_to_doc(text),
      explanation: explanation.presence,
      answer_type: :exact_value,
      grading: { "expected" => answer.to_s.strip },
      status: :in_review,
      author: suggested_by,
      suggested_by: suggested_by,
      elo: suggested_by.elo,
      topics: [ topic ].compact
    )
  end

  private

  def topic
    @topic ||= Topic.find_by(id: topic_id)
  end

  def answer_is_a_value
    return if answer.blank?

    errors.add(:answer, :not_a_value) if ExactValue.parse(answer).nil?
  end

  def topic_exists
    errors.add(:topic_id, :blank) if topic_id.present? && topic.nil?
  end

  # body_text is what the importer dedupes on; the same guard here keeps a
  # well-known problem from entering the queue twice.
  def problem_is_new
    return if text.blank?

    body_text = RichContent.plain_text(RichContent.text_to_doc(text))
    errors.add(:text, :already_known) if Question.exists?(body_text: body_text)
  end
end
