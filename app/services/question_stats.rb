# How students have actually fared with a question, read off user_answers for
# the admin browser and editor. Three outcomes, the same three the student
# sees: right, wrong and „не съм го учил". A free-text answer waiting for a
# grader is none of them (`correct` is false only because it has to be
# something), so it is left out of every count here.
module QuestionStats
  Split = Struct.new(:correct, :wrong, :skipped) do
    def attempted = correct + wrong
    def total = attempted + skipped

    def share(part)
      total.zero? ? 0 : (send(part) * 100.0 / total).round
    end
  end

  EMPTY = Split.new(0, 0, 0).freeze

  COUNTED = "COALESCE(user_answers.response->>'verdict', '') <> 'pending_review'".freeze

  # Every question's counts in one pass, as a relation to join against when the
  # browser sorts or filters by them (most skipped, „Много пропускани").
  BANK_SQL = <<~SQL.squish.freeze
    SELECT assignment_questions.question_id,
           count(*) AS total,
           count(*) FILTER (WHERE user_answers.skipped) AS skipped
    FROM user_answers
    JOIN assignment_questions ON assignment_questions.id = user_answers.assignment_question_id
    WHERE #{COUNTED}
    GROUP BY assignment_questions.question_id
  SQL

  module_function

  def answers_to(question_ids)
    UserAnswer.joins(:assignment_question).
      where(assignment_questions: { question_id: question_ids }).
      where(COUNTED)
  end

  # One grouped query for a page of questions: { id => Split }.
  def for(question_ids)
    rows = answers_to(question_ids).group("assignment_questions.question_id").pluck(
      Arel.sql("assignment_questions.question_id"),
      Arel.sql("count(*) FILTER (WHERE user_answers.correct)"),
      Arel.sql("count(*) FILTER (WHERE NOT user_answers.correct AND NOT user_answers.skipped)"),
      Arel.sql("count(*) FILTER (WHERE user_answers.skipped)")
    )
    rows.to_h { |id, correct, wrong, skipped| [ id, Split.new(correct, wrong, skipped) ] }
  end

  def split(question)
    self.for([ question.id ]).fetch(question.id, EMPTY)
  end

  # The wrong answer given most often, and what share of the wrong answers it
  # is — the usual reason a question is „hard" is one tempting mistake, and
  # its text is the fix. Only for answers that are a line of text: a widget's
  # stored state reads as nothing a person would recognise.
  def common_wrong(question)
    return unless question.multiple_choice? || question.exact_value?

    wrong = answers_to(question.id).where(correct: false, skipped: false)
    value, count = wrong.group(:value).order(Arel.sql("count(*) DESC"), :value).limit(1).count.first
    return if value.blank?

    { value: value, count: count, share: (count * 100.0 / wrong.count).round }
  end

  # How many students chose each option: { option_id => students }. The
  # editor warns before an option somebody already picked is reworded or
  # removed: their answer keeps its verdict and its stored wording, so what
  # they chose and what the option now says quietly stop matching.
  def option_choosers(question)
    return {} unless question.multiple_choice?

    answers_to(question.id).where(skipped: false).
      joins("CROSS JOIN LATERAL jsonb_array_elements_text(user_answers.response->'selected_ids') AS chosen(option_id)").
      group(Arel.sql("chosen.option_id::bigint")).
      distinct.count(:user_id)
  end
end
