# How an answer reads back to the child. Most answers are a short string
# (`user_answers.value`), but a filled-in table is a set of cells, and written
# out as a string it was „0,1: 170, 1,0: 162…" — coordinates a child cannot
# read, struck through whole although four of five cells were right. A table is
# shown back as a table, and anywhere there is room for only one line, as how
# many of its cells were right.
module WidgetAnswersHelper
  def grid_fill_question?(question)
    question.interactive? && question.widget_type == "grid_fill"
  end

  # Each asked-for cell ("r,c") with what was expected, what was given and
  # whether it was right. `answer` is nil when there is nothing given to show
  # (a skip), and then only the expected values are known.
  def grid_fill_cells(question, answer)
    expected = question.grading&.dig("solution", "cells") || {}
    given = (answer && !answer.skipped? && answer.response.is_a?(Hash) && answer.response.dig("state", "cells")) || {}

    expected.to_h do |cell, value|
      typed = given[cell.to_s].to_s.strip
      [ cell.to_s, { expected: value, given: typed.presence, right: typed.present? && ExactValue.equivalent?(value, typed) } ]
    end
  end

  # One line for a list row: the answer as written, or for a table „4 от 5
  # клетки".
  def answer_value(question, answer)
    return math_value(answer.value) unless grid_fill_question?(question) && !answer.skipped?

    cells = grid_fill_cells(question, answer)
    t("answers.grid_cells_right", right: cells.count { |_, cell| cell[:right] }, total: cells.size)
  end

  # Whether the struck-through style suits the line `answer_value` shows: a
  # count of cells is a sentence, not a value that was wrong.
  def struck_answer?(question, answer)
    !fraction_value?(answer.value) && !grid_fill_question?(question)
  end
end
