# One admin change to a question: who, when, and the fields that moved as
# [before, after]. Written by the admin editor (create, save, hide, retire,
# restore) and read by its „История" card; nothing else writes a question's
# history, so an imported question has none and says so.
class QuestionRevision < ApplicationRecord
  belongs_to :question
  belongs_to :author, class_name: "User", optional: true

  ACTIONS = %w[created updated hidden retired restored].freeze
  # The fields a revision compares, in the order the card lists them.
  FIELDS = %w[body options answer explanation elo topics status hints].freeze

  validates :action, inclusion: { in: ACTIONS }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  # The question as the editor shows it, flattened to strings and lists so two
  # of them compare with == and a revision reads without the row it is about.
  def self.snapshot(question)
    question = Question.includes(:possible_answers, :topics, :hint).find(question.id) if question.persisted?

    {
      "body" => question.body_text.to_s,
      "options" => question.multiple_choice? ? question.possible_answers.reject(&:marked_for_destruction?).map { |option| option_label(option) } : [],
      "answer" => Grading.correct_answer_display(question).to_s,
      "explanation" => question.explanation.to_s,
      "elo" => question.elo,
      "topics" => question.topics.map(&:name).sort,
      "status" => question.status,
      "hints" => question.hint&.ladder.to_a
    }
  end

  def self.option_label(option)
    option.correct? ? "#{option.value} ✓" : option.value.to_s
  end

  # Records what moved between `before` (a snapshot, or nil for a new
  # question) and the question as it now stands. An update that changed
  # nothing the card shows records nothing.
  def self.record!(question, author:, action:, before: nil)
    after = snapshot(question)
    diff = FIELDS.each_with_object({}) do |field, changed|
      old = before&.fetch(field, nil)
      changed[field] = [ old, after[field] ] if old != after[field] && (before || after[field].present?)
    end
    return if diff.empty? && action == "updated"

    create!(question: question, author: author, action: action, diff: diff)
  end
end
