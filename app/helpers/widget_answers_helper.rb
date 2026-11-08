# How an answer reads back to the child. Most answers are a short string
# (`user_answers.value`), but a filled-in table is a set of cells, and written
# out as a string it was „0,1: 170, 1,0: 162…" — coordinates a child cannot
# read, struck through whole although four of five cells were right. A table is
# shown back as a table, and anywhere there is room for only one line, as how
# many of its cells were right. An operation chain is the same kind of answer —
# boxes in a picture — and is drawn back the same way: as one line it was
# „2, 2, 4, 3, 1; 4, 1, 3, 2, 5".
module WidgetAnswersHelper
  # The widgets whose answer is a set of boxes in a drawing, and the key their
  # solution and state keep the boxes under.
  DRAWN_ANSWERS = { "grid_fill" => "cells", "operation_chain" => "values" }.freeze

  def drawn_answer?(question)
    question.interactive? && DRAWN_ANSWERS.key?(question.widget_type)
  end

  # answers/_grid_fill_review, answers/_operation_chain_review.
  def drawn_answer_partial(question) = "answers/#{question.widget_type}_review"

  # Each asked-for box (a grid's "r,c", a chain's "0.tl") with what was
  # expected, what was given and whether it was right. `answer` is nil when
  # there is nothing given to show (a skip, or the question inside a report),
  # and then only the expected values are known.
  def answer_boxes(question, answer)
    key = DRAWN_ANSWERS.fetch(question.widget_type)
    expected = question.grading&.dig("solution", key) || {}
    given = (answer && !answer.skipped? && answer.response.is_a?(Hash) && answer.response.dig("state", key)) || {}

    expected.to_h do |box, value|
      typed = given[box.to_s].to_s.strip
      [ box.to_s, { expected: value, given: typed.presence, right: typed.present? && ExactValue.equivalent?(value, typed) } ]
    end
  end

  # One line for a list row: the answer as written, or for a table „4 от 5
  # клетки".
  def answer_value(question, answer)
    return math_value(answer.value) unless drawn_answer?(question) && !answer.skipped?

    boxes = answer_boxes(question, answer)
    t("answers.grid_cells_right", right: boxes.count { |_, box| box[:right] }, total: boxes.size)
  end

  # Whether the struck-through style suits the line `answer_value` shows: a
  # count of cells is a sentence, not a value that was wrong.
  def struck_answer?(question, answer)
    !fraction_value?(answer.value) && !drawn_answer?(question)
  end

  # Where the squares, signs and arrows of an operation chain go — the same
  # numbers widgets/operation_chain_controller.js draws with.
  CHAIN_SQUARE = 44
  CHAIN_STEP = [ 52, 72 ].freeze
  CHAIN_PLACES = { "tl" => [ 0, 0 ], "tr" => [ 2, 0 ], "m" => [ 1, 1 ], "r" => [ 3, 1 ], "b" => [ 2, 2 ] }.freeze
  CHAIN_OPS = [ [ 1, 0 ], [ 2, 1 ] ].freeze
  CHAIN_ARROWS = [ %w[tl m], %w[tr m], %w[m b], %w[r b] ].freeze

  def chain_size = [ (3 * CHAIN_STEP[0]) + CHAIN_SQUARE, (2 * CHAIN_STEP[1]) + CHAIN_SQUARE ]

  def chain_at(col, row) = "left: #{col * CHAIN_STEP[0]}px; top: #{row * CHAIN_STEP[1]}px; width: #{CHAIN_SQUARE}px; height: #{CHAIN_SQUARE}px"

  # From the bottom edge of one square to the top edge of the next.
  def chain_arrows
    centre = ->(place) { CHAIN_PLACES[place].each_with_index.map { |n, axis| (n * CHAIN_STEP[axis]) + (CHAIN_SQUARE / 2.0) } }
    CHAIN_ARROWS.map do |from, to|
      (x1, y1), (x2, y2) = centre.(from), centre.(to)
      t1 = ((CHAIN_SQUARE / 2.0) + 2) / (y2 - y1)
      t2 = ((CHAIN_SQUARE / 2.0) + 3) / (y2 - y1)
      [ x1 + ((x2 - x1) * t1), y1 + ((y2 - y1) * t1), x2 - ((x2 - x1) * t2), y2 - ((y2 - y1) * t2) ].map { |n| n.round(1) }
    end
  end
end
