# Builders for the twenty interactive widgets, so a family says what the student
# has to do rather than assembling JSON.
#
# Each returns the `widget` hash the importer stores in `questions.grading`:
# {"widget" => key, "params" => shown to the student, "solution" => never sent}.
# Whatever goes in `params` reaches the browser, so nothing that gives the answer
# away belongs there.
module WidgetKit
  module_function

  # --- placing ---------------------------------------------------------------

  def number_line(min:, max:, step:, value:, tolerance: 0)
    { "widget" => "number_line",
      "params" => { "min" => min, "max" => max, "step" => step },
      "solution" => { "value" => value, "tolerance" => tolerance } }
  end

  def angle_dial(degrees:, tolerance: 0, step: 5, max: 180)
    { "widget" => "angle_dial",
      "params" => { "step" => step, "max" => max },
      "solution" => { "degrees" => degrees, "tolerance" => tolerance } }
  end

  def clock(hours:, minutes:, minute_step: 5, tolerance: 0)
    { "widget" => "clock_hands",
      "params" => { "minute_step" => minute_step },
      "solution" => { "hours" => hours, "minutes" => minutes, "tolerance" => tolerance } }
  end

  # points: [[x, y], ...] the student must place. fixed: points drawn for them.
  def plot(points:, x_range: (-5..5), y_range: (-5..5), fixed: [])
    { "widget" => "coordinate_plot",
      "params" => { "min_x" => x_range.min, "max_x" => x_range.max,
                    "min_y" => y_range.min, "max_y" => y_range.max,
                    "count" => points.size, "fixed" => fixed },
      "solution" => { "points" => points } }
  end

  # --- arranging -------------------------------------------------------------

  # items: [[id, label], ...] already in the correct order.
  def ordering(items)
    { "widget" => "ordering",
      "params" => { "items" => items.map { |id, label| { "id" => id.to_s, "label" => label.to_s } } },
      "solution" => { "order" => items.map { |id, _| id.to_s } } }
  end

  # bins: [[id, label], ...]; items: [[id, label, bin_id], ...]
  def categorize(bins:, items:)
    { "widget" => "categorize",
      "params" => { "bins" => bins.map { |id, label| { "id" => id.to_s, "label" => label.to_s } },
                    "items" => items.map { |id, label, _| { "id" => id.to_s, "label" => label.to_s } } },
      "solution" => { "assignment" => items.to_h { |id, _, bin| [ id.to_s, bin.to_s ] } } }
  end

  # pairs: [[left_label, right_label], ...]
  def matcher(pairs)
    { "widget" => "matcher",
      "params" => { "left" => pairs.each_with_index.map { |(label, _), i| { "id" => "l#{i}", "label" => label.to_s } },
                    "right" => pairs.each_with_index.map { |(_, label), i| { "id" => "r#{i}", "label" => label.to_s } } },
      "solution" => { "pairs" => pairs.each_index.to_h { |i| [ "l#{i}", "r#{i}" ] } } }
  end

  # --- choosing --------------------------------------------------------------

  # options: [[label, correct?], ...]
  def multi_select(options)
    entries = options.each_with_index.map { |(label, correct), i| [ "o#{i}", label.to_s, correct ] }
    { "widget" => "multi_select",
      "params" => { "options" => entries.map { |id, label, _| { "id" => id, "label" => label } } },
      "solution" => { "correct" => entries.select { |_, _, correct| correct }.map(&:first) } }
  end

  # --- filling in ------------------------------------------------------------

  # fields: [[id, label, value, unit?], ...]
  def blanks(fields, prompt: nil, tolerance: nil)
    params = { "fields" => fields.map { |id, label, _, unit| { "id" => id.to_s, "label" => label.to_s }.merge(unit ? { "unit" => unit } : {}) } }
    params["prompt"] = prompt if prompt
    solution = { "values" => fields.to_h { |id, _, value, _| [ id.to_s, value.to_s ] } }
    solution["tolerance"] = tolerance if tolerance

    { "widget" => "blanks", "params" => params, "solution" => solution }
  end

  # rows: the grid as it is shown, with nil where the student has to write.
  # answers: the same grid with every value filled in.
  def grid_fill(rows:, answers:, column_headers: [], row_headers: [])
    solution = {}
    rows.each_with_index do |row, r|
      row.each_with_index { |cell, c| solution["#{r},#{c}"] = answers[r][c].to_s if cell.nil? }
    end

    { "widget" => "grid_fill",
      "params" => { "rows" => rows, "column_headers" => column_headers, "row_headers" => row_headers },
      "solution" => solution.then { |cells| { "cells" => cells } } }
  end

  # An exact set of cells ("r,c" strings), a count — "shade any six" — or a
  # rectangle of two sides, either way round, pinned to the top-left `corner`
  # when the text puts it there.
  def grid_shade(rows:, cols:, cells: nil, count: nil, rectangle: nil, corner: false, given: [], axis: false)
    solution = if rectangle
      { "rectangle" => rectangle, "corner" => corner }
    else
      cells ? { "cells" => cells } : { "count" => count }
    end

    { "widget" => "grid_shade",
      "params" => { "rows" => rows, "cols" => cols, "given" => given, "axis" => axis },
      "solution" => solution }
  end

  def fraction_bars(segments:, shaded:)
    { "widget" => "fraction_bars",
      "params" => { "segments" => segments },
      "solution" => { "shaded" => shaded } }
  end

  # --- showing the working ---------------------------------------------------

  # Written addition or subtraction: operands are whole numbers, op "+" or "−".
  def column_arithmetic(operands:, op:)
    result = op == "+" ? operands.sum : operands.first - operands.drop(1).sum
    raise ArgumentError, "column subtraction below zero" if result.negative?

    { "widget" => "column_arithmetic",
      "params" => { "operands" => operands.map(&:to_s), "op" => op },
      "solution" => { "result" => result.to_s } }
  end

  # ax + b = cx + d on two pans. steps: one way to solve it, as the moves the
  # student would make — stored for the checks, never sent to the page.
  def balance_scale(left:, right:, x:, steps:)
    side = ->((xs, units)) { { "x" => xs, "units" => units } }
    { "widget" => "balance_scale",
      "params" => { "left" => side.(left), "right" => side.(right) },
      "solution" => { "x" => x, "steps" => steps.map { |op, k| { "op" => op.to_s, "k" => k } } } }
  end

  # shape: polygon / triangle / right_triangle / rectangle / square, plus an
  # optional area and perimeter; example: one polygon that fits, as [col, row]
  # pegs, kept for the checks.
  def geoboard(shape:, example:, area: nil, perimeter: nil, size: 7)
    solution = { "shape" => shape.to_s, "points" => example }
    solution["area"] = area if area
    solution["perimeter"] = perimeter if perimeter

    { "widget" => "geoboard", "params" => { "size" => size }, "solution" => solution }
  end

  # angles: every angle (degrees, 0-359) the student has to mark. values: show
  # the sine and cosine of the selected point as numbers — right for a question
  # about where an angle lies, wrong for one that asks for those very numbers.
  # degrees: show the selected angle in degrees — wrong for "mark 120°", which
  # would then be a matter of tapping until the readout says 120.
  def unit_circle(angles:, step: 15, values: false, degrees: true)
    { "widget" => "unit_circle",
      "params" => { "step" => step, "count" => angles.size, "values" => values, "degrees" => degrees },
      "solution" => { "angles" => angles.sort } }
  end

  # lines: the worked solution, the problem first; wrong: the index of the line
  # the mistake is made on (1 or later).
  def find_mistake(lines:, wrong:)
    { "widget" => "find_mistake",
      "params" => { "lines" => lines },
      "solution" => { "line" => wrong } }
  end

  # start + change on an open number line in hops of the given sizes; hops: one
  # way to get there, for the checks.
  def number_hops(start:, change:, sizes:, hops:)
    { "widget" => "number_hops",
      "params" => { "start" => start, "change" => change, "hops" => sizes },
      "solution" => { "value" => (start + change).to_s, "hops" => hops } }
  end

  # A figure to tap equal parts in. points: {"A" => [x, y], ...} on a 0-100
  # board, y downwards. segments: [["A", "M"], ...]; angles: [["A", "C", "M"],
  # ...] as [from, vertex, to]. given: the highlighted part, written the same
  # way; equal: the parts equal to it. lines: construction lines drawn dashed
  # and never tappable, [["P", "Q", "s"], ...] with an optional label.
  def equal_parts(points:, given:, equal:, segments: [], angles: [], lines: [])
    parts = segments.map { |from, to| [ "s:#{from}#{to}", { "from" => from, "to" => to } ] } +
            angles.map { |from, vertex, to| [ "a:#{from}#{vertex}#{to}", { "from" => from, "vertex" => vertex, "to" => to } ] }
    id_of = ->(part) { part.size == 2 ? "s:#{part.join}" : "a:#{part.join}" }
    ids = parts.map(&:first)
    [ given, *equal ].each { |part| raise ArgumentError, "#{part.join} is not a part of the figure" unless ids.include?(id_of.(part)) }

    { "widget" => "equal_parts",
      "params" => {
        "points" => points.transform_values { |x, y| [ x.round(1), y.round(1) ] },
        "segments" => parts.select { |id, _| id.start_with?("s:") }.map { |id, part| part.merge("id" => id) },
        "angles" => parts.select { |id, _| id.start_with?("a:") }.map { |id, part| part.merge("id" => id) },
        "lines" => lines.map { |from, to, label| { "from" => from, "to" => to, "label" => label }.compact },
        "given" => id_of.(given)
      },
      "solution" => { "parts" => equal.map(&id_of) } }
  end

  # direction: "right" for x > edge / x ≥ edge, "left" for x < edge / x ≤ edge.
  def inequality_line(edge:, closed:, direction:, min: -6, max: 6, step: 1)
    { "widget" => "inequality_line",
      "params" => { "min" => min, "max" => max, "step" => step },
      "solution" => { "edge" => edge, "closed" => closed, "direction" => direction.to_s } }
  end
end
