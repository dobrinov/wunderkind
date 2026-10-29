# What review mode can tell about a suggested problem before a person reads
# it: the checks the authoring toolchain runs on the shipped bank
# (tools/authoring/check.rb), the ones that apply to a problem typed into a
# form, plus where it would sit among the problems already published.
#
# Only checks a machine can actually make. Whether the stated answer is the
# *right* answer is not one of them — a parsed value is not a solved problem —
# so the first check says „the answer reads as a value", never „the answer is
# correct".
class SuggestionChecks
  Check = Data.define(:key, :state, :detail) # state: :ok, :warn or :fail

  # check.rb's own pattern for a fraction in a problem's text.
  FRACTION = %r{(?<![\d,/])\d+/\d+(?![\d/])}
  NEAREST = 3

  attr_reader :question

  def initialize(question)
    @question = question
  end

  def checks
    [ answer_check, explanation_check, options_check, duplicate_check ].compact
  end

  # Published problems on the same template (the text with its numbers
  # blanked, SessionComposer::SHAPE_SQL): how many, and the median of their
  # ratings, which is the honest guess at this one's — the suggester's own
  # rating is only where they stand.
  def same_template
    @same_template ||= begin
      scope = Question.published.where("#{SessionComposer::SHAPE_SQL} = :shape", shape: ProblemSeeds.shape_of(question.body_text))
      count, median = scope.pick(Arel.sql("count(*)"), Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY questions.elo)"))
      { count: count.to_i, median: median&.round }
    end
  end

  def suggested_elo
    same_template[:median]
  end

  # The published problems of the same topic nearest in rating, to read
  # beside it.
  def nearest
    return Question.none if question.topic_ids.empty?

    Question.published.where(id: Question.joins(:topics).where(topics: { id: question.topic_ids }).select(:id)).
      where.not(id: question.id).
      order(Arel.sql("abs(questions.elo - #{question.elo.to_i}), questions.id")).limit(NEAREST)
  end

  private

  def answer_check
    if question.multiple_choice?
      correct = question.possible_answers.select(&:correct?)
      return Check.new(:answer_none, :fail, nil) if correct.empty?

      Check.new(:answer_marked, :ok, correct.map(&:value).join(", "))
    elsif question.exact_value?
      expected = question.grading["expected"].to_s
      ExactValue.parse(expected) ? Check.new(:answer_parses, :ok, expected) : Check.new(:answer_unparsed, :fail, expected)
    end
  end

  # An explanation that never mentions a fraction the problem shows was
  # written for different numbers, or is not about this problem.
  def explanation_check
    explanation = question.explanation.to_s
    return Check.new(:explanation_missing, :warn, nil) if explanation.strip.empty?

    missing = question.body_text.to_s.scan(FRACTION).uniq.reject { |fraction| explanation.include?(fraction) }
    missing.empty? ? Check.new(:explanation_fractions, :ok, nil) : Check.new(:explanation_skips, :warn, missing.join(", "))
  end

  def options_check
    return unless question.multiple_choice?

    count = question.possible_answers.size
    Check.new(:few_options, :warn, count) if count < 3
  end

  # The same text is what the importer and the suggestion form dedupe on; an
  # admin edit in review can still make one.
  def duplicate_check
    twin = Question.where(body_text: question.body_text).where.not(id: question.id).pick(:id)
    twin ? Check.new(:duplicate, :fail, twin) : Check.new(:unique, :ok, nil)
  end
end
