# Builders for the twelve interactive widgets, so a family says what the student
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

  # Either an exact set of cells ("r,c" strings) or a count — "shade any six".
  def grid_shade(rows:, cols:, cells: nil, count: nil, given: [], axis: false)
    { "widget" => "grid_shade",
      "params" => { "rows" => rows, "cols" => cols, "given" => given, "axis" => axis },
      "solution" => cells ? { "cells" => cells } : { "count" => count } }
  end

  def fraction_bars(segments:, shaded:)
    { "widget" => "fraction_bars",
      "params" => { "segments" => segments },
      "solution" => { "shaded" => shaded } }
  end
end
