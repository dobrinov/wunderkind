# Grades a student's raw response against a question, per answer type.
# Returns a Result with the verdict, a normalized response payload for storage,
# and a human-readable rendering of what the student answered.
module Grading
  UnsupportedAnswerType = Class.new(StandardError)

  Result = Struct.new(:correct, :response, :display_value, keyword_init: true)

  module_function

  def grade(question:, raw:, user: nil)
    case question.answer_type
    when "multiple_choice" then grade_multiple_choice(question, raw)
    when "exact_value" then grade_exact_value(question, raw)
    when "interactive" then grade_interactive(question, raw)
    when "free_text" then grade_free_text(question, raw, user)
    else
      raise UnsupportedAnswerType, question.answer_type
    end
  end

  def correct_answer_display(question)
    case question.answer_type
    when "multiple_choice"
      question.correct_possible_answers.map(&:value).join(", ")
    when "exact_value"
      question.grading["expected"].to_s
    when "interactive"
      Widgets.solution_display(question.widget_type,
                               solution: question.grading["solution"],
                               params: question.grading["params"])
    when "free_text"
      question.grading["rubric"].to_s
    else
      ""
    end
  end

  # True when the submission carries nothing to grade — no option picked, an
  # empty field, a widget the student never touched. Grading it would cost Elo
  # and XP for an answer the student either never gave or the client dropped.
  def blank_response?(question:, raw:)
    case question.answer_type
    when "multiple_choice" then selected_ids(raw).empty?
    when "exact_value", "free_text" then raw[:value].to_s.strip.empty?
    when "interactive" then raw[:state].blank?
    else false
    end
  end

  # Free-text answers are graded by a person: they land as pending review and
  # the homework assigner accepts or rejects them via AnswerOverridesController.
  def grade_free_text(question, raw, _user)
    answer = raw[:value].to_s.strip

    Result.new(
      correct: false,
      response: { "value" => answer, "verdict" => "pending_review" },
      display_value: answer
    )
  end

  def selected_ids(raw)
    Array(raw[:selected_ids]).map(&:to_i).reject(&:zero?).sort
  end

  def grade_multiple_choice(question, raw)
    selected_ids = selected_ids(raw)
    correct_ids = question.correct_possible_answers.map(&:id).sort
    selected = question.possible_answers.select { |option| selected_ids.include?(option.id) }

    Result.new(
      correct: selected_ids.present? && selected_ids == correct_ids,
      response: { "selected_ids" => selected_ids },
      display_value: selected.map(&:value).join(", ")
    )
  end

  def grade_exact_value(question, raw)
    value = raw[:value].to_s.strip

    Result.new(
      correct: ExactValue.equivalent?(question.grading["expected"], value, tolerance: question.grading["tolerance"]),
      response: { "value" => value },
      display_value: value
    )
  end

  def grade_interactive(question, raw)
    state = raw[:state].is_a?(String) ? JSON.parse(raw[:state]) : raw[:state].to_h
    state = state.deep_stringify_keys

    Result.new(
      correct: Widgets.correct?(question.widget_type, solution: question.grading["solution"], state: state, params: question.grading["params"]),
      response: { "state" => state },
      display_value: Widgets.display(question.widget_type, state: state, params: question.grading["params"])
    )
  rescue JSON::ParserError
    Result.new(correct: false, response: { "state" => {} }, display_value: "")
  end
end
