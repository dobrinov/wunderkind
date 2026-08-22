# A problem suggested by any user — student, parent or admin. The form is
# still a lighter door than the authoring editor — one topic, no widgets, no
# status — but it speaks the same language: the problem is written in the rich
# editor (math notation included; a bare "1/2" is promoted to a fraction
# exactly as problem files are), the answer is either a value a student could
# type or a set of options with the right ones marked, and a picture can ride
# along. What comes out is an ordinary Question headed for the admin review
# queue, carrying `suggested_by` so the suggester is credited wherever the
# problem is asked.
class Suggestion
  include ActiveModel::Model

  # The two answer shapes a suggester can build. Widgets stay with the
  # authoring toolchain, free text with Phase 3.
  ANSWER_TYPES = %w[exact_value multiple_choice].freeze
  MIN_OPTIONS = 2
  IMAGE_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze

  attr_accessor :text, :body_json, :answer, :image, :explanation, :topic_id, :suggested_by
  attr_writer :answer_type

  validates :topic_id, presence: true
  validates :answer_type, inclusion: { in: ANSWER_TYPES }
  validates :answer, presence: true, if: :exact_value?
  validate :body_is_present
  validate :answer_is_a_value, if: :exact_value?
  validate :options_make_a_choice, if: :multiple_choice?
  validate :image_is_an_image
  validate :topic_exists
  validate :problem_is_new

  def save
    return false unless valid?

    question.save!
    true
  end

  def answer_type
    @answer_type.presence || "exact_value"
  end

  def exact_value? = answer_type == "exact_value"
  def multiple_choice? = answer_type == "multiple_choice"

  # Rows arrive keyed by index from the form, as an array from code; blank
  # rows are the untouched extras and drop out.
  def options=(rows)
    rows = rows.values if rows.respond_to?(:values)
    @options = Array(rows).map { |row| row.to_h.symbolize_keys }
                          .map { |row| { value: row[:value].to_s.strip, correct: ActiveModel::Type::Boolean.new.cast(row[:correct]) || false } }
                          .reject { |row| row[:value].blank? }
  end

  def options = @options ||= []

  # What the form renders: the submitted rows on a redisplay, blanks to start with.
  def option_rows
    options.presence || Array.new(MIN_OPTIONS) { { value: "", correct: false } }
  end

  # What the editor reopens with on a redisplay: exactly what was submitted.
  def body_doc
    parsed_body_json || {}
  end

  # The question the suggestion becomes. Difficulty starts at the suggester's
  # own rating — people propose problems from where they stand — and the admin
  # adjusts it in review if the guess is off.
  def question
    @question ||= Question.new(
      body: body,
      explanation: explanation.presence,
      answer_type: answer_type,
      grading: grading,
      status: :in_review,
      author: suggested_by,
      suggested_by: suggested_by,
      elo: suggested_by.elo,
      topics: [ topic ].compact,
      attachable: image.present? ? QuestionImage.new(file: image) : nil,
      possible_answers: possible_answers
    )
  end

  private

  # The editor submits the document itself; the plain-text path (seeds, and
  # anything else that speaks in strings) still goes through text_to_doc.
  # Either way bare fractions come out as math nodes, like a problem file's.
  def body
    @body ||= if parsed_body_json.present?
      RichContent.promote_fractions(parsed_body_json)
    else
      RichContent.text_to_doc(text)
    end
  end

  def parsed_body_json
    return @parsed_body_json if defined?(@parsed_body_json)

    @parsed_body_json = begin
      JSON.parse(body_json.to_s)
    rescue JSON::ParserError
      nil
    end
  end

  def body_text
    @body_text ||= RichContent.plain_text(body)
  end

  def grading
    exact_value? ? { "expected" => answer.to_s.strip } : {}
  end

  def possible_answers
    return [] unless multiple_choice?

    options.each_with_index.map do |option, index|
      PossibleAnswer.new(value: option[:value], correct: option[:correct], position: index + 1)
    end
  end

  def topic
    @topic ||= Topic.find_by(id: topic_id)
  end

  # An empty editor still serializes a document, so presence is judged on the
  # text projection, not on the params.
  def body_is_present
    errors.add(:text, :blank) if body_text.blank?
  end

  def answer_is_a_value
    return if answer.blank?

    errors.add(:answer, :not_a_value) if ExactValue.parse(answer).nil?
  end

  def options_make_a_choice
    errors.add(:options, :too_few) if options.size < MIN_OPTIONS
    errors.add(:options, :none_correct) if options.any? && options.none? { |option| option[:correct] }
  end

  def image_is_an_image
    return if image.blank?

    errors.add(:image, :not_an_image) unless IMAGE_TYPES.include?(image.content_type)
  end

  def topic_exists
    errors.add(:topic_id, :blank) if topic_id.present? && topic.nil?
  end

  # body_text is what the importer dedupes on; the same guard here keeps a
  # well-known problem from entering the queue twice.
  def problem_is_new
    return if body_text.blank?

    errors.add(:text, :already_known) if Question.exists?(body_text: body_text)
  end
end
