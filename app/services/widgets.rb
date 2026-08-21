# The curated interactive widget registry. Each widget has a server-side checker
# (the correct answer never reaches the client) and a display projection used to
# show the student's response back to them.
#
# A widget is worth adding when it lets a student *do* the mathematics rather
# than name it: place a point, shade a region, sort into groups, fill a table.
# Everything here is checked from the submitted state alone — a widget whose
# answer cannot be decided server-side does not belong in this file.
module Widgets
  # `display` projects the student's own state; `solution_display` projects the
  # stored solution the same way, for the "correct answer" chip. Most widgets
  # store the solution in the shape of a finished state and need only the one
  # lambda — the two that don't (a set of ids under another key, a count with no
  # cells at all) would otherwise show the student an empty box.
  Definition = Struct.new(:key, :checker, :display, :solution_display, keyword_init: true)

  module_function

  # Labels for a set of ids, in the order the ids are given.
  def labels_for(params, key, ids)
    lookup = Array(params[key]).index_by { |item| item["id"].to_s }
    Array(ids).map { |id| lookup.dig(id.to_s, "label") || id }
  end

  # Labels for a set of ids, in the order the params list the options. A set of
  # choices has no order of its own, so the order they happened to be clicked in
  # is noise — and it reads as noise next to a solution listed option by option.
  def labels_in_order(params, key, ids)
    options = Array(params[key])
    return labels_for(params, key, ids) if options.empty?

    wanted = Array(ids).map(&:to_s)
    options.filter_map { |item| item["label"] if wanted.include?(item["id"].to_s) }
  end

  # A chosen set, written out. Options are usually single numbers and a comma
  # reads best, but an option can be a list of its own ("10, 14, 18, 22") and
  # then commas would fuse the choices into one long number sequence.
  def join_choices(labels)
    labels.any? { |label| label.to_s.include?(",") } ? labels.join(" | ") : labels.join(", ")
  end

  def point_key(pair) = Array(pair).first(2).map { |value| value.to_f.round(3) }

  REGISTRY = {
    # --- placing a value ---------------------------------------------------
    "number_line" => Definition.new(
      key: "number_line",
      checker: ->(solution, state, _params) {
        value = state["value"]
        return false if value.nil?

        tolerance = solution.fetch("tolerance", 0).to_f
        (value.to_f - solution["value"].to_f).abs <= tolerance
      },
      display: ->(state, _params) { state["value"].to_s }
    ),

    # A ray the student rotates: "set an angle of 135°", "how big is this angle".
    "angle_dial" => Definition.new(
      key: "angle_dial",
      checker: ->(solution, state, _params) {
        degrees = state["degrees"]
        return false if degrees.nil?

        tolerance = solution.fetch("tolerance", 0).to_f
        (degrees.to_f - solution["degrees"].to_f).abs <= tolerance
      },
      display: ->(state, _params) { state["degrees"].nil? ? "" : "#{state['degrees']}°" }
    ),

    # Hands on a clock face. Hours are compared modulo 12 — a clock cannot tell
    # morning from afternoon, and neither should the grader.
    "clock_hands" => Definition.new(
      key: "clock_hands",
      checker: ->(solution, state, _params) {
        return false if state["hours"].nil? || state["minutes"].nil?

        tolerance = solution.fetch("tolerance", 0).to_i
        (state["hours"].to_i % 12) == (solution["hours"].to_i % 12) &&
          (state["minutes"].to_i - solution["minutes"].to_i).abs <= tolerance
      },
      display: ->(state, _params) {
        state["hours"].nil? ? "" : format("%d:%02d", state["hours"].to_i, state["minutes"].to_i)
      }
    ),

    # Lattice points on a coordinate plane. The order they are placed in never
    # matters — three vertices of a triangle are the same triangle either way.
    "coordinate_plot" => Definition.new(
      key: "coordinate_plot",
      checker: ->(solution, state, _params) {
        placed = Array(state["points"]).map { |point| Widgets.point_key(point) }.uniq.sort
        expected = Array(solution["points"]).map { |point| Widgets.point_key(point) }.uniq.sort

        expected.present? && placed == expected
      },
      display: ->(state, _params) {
        Array(state["points"]).map { |x, y| "(#{x}; #{y})" }.join(", ")
      }
    ),

    # --- arranging -----------------------------------------------------------
    "ordering" => Definition.new(
      key: "ordering",
      checker: ->(solution, state, _params) {
        state["order"].present? && state["order"].map(&:to_s) == solution["order"].map(&:to_s)
      },
      display: ->(state, params) { Widgets.labels_for(params, "items", state["order"]).join(" → ") }
    ),

    # Every item into one of a few named groups: prime or composite, quadrilateral
    # or not, rational or irrational.
    "categorize" => Definition.new(
      key: "categorize",
      checker: ->(solution, state, _params) {
        expected = solution["assignment"] || {}
        given = state["assignment"] || {}

        expected.present? && expected.all? { |item, bin| given[item.to_s].to_s == bin.to_s }
      },
      display: ->(state, params) {
        assignment = state["assignment"] || {}
        Array(params["bins"]).filter_map do |bin|
          items = assignment.select { |_, value| value.to_s == bin["id"].to_s }.keys
          next if items.empty?

          "#{bin['label']}: #{Widgets.labels_for(params, 'items', items).join(', ')}"
        end.join(" | ")
      }
    ),

    # Pairs: expression to value, shape to name, fraction to percent.
    "matcher" => Definition.new(
      key: "matcher",
      checker: ->(solution, state, _params) {
        expected = solution["pairs"] || {}
        given = state["pairs"] || {}

        expected.present? && expected.all? { |left, right| given[left.to_s].to_s == right.to_s }
      },
      display: ->(state, params) {
        pairs = state["pairs"] || {}
        Array(params["left"]).filter_map do |item|
          right = pairs[item["id"].to_s]
          next if right.blank?

          "#{item['label']} → #{Widgets.labels_for(params, 'right', [ right ]).first}"
        end.join(", ")
      }
    ),

    # --- choosing ------------------------------------------------------------
    # Select every option that fits. Unlike multiple choice this has no "one
    # right button": the student has to judge each option on its own.
    "multi_select" => Definition.new(
      key: "multi_select",
      checker: ->(solution, state, _params) {
        chosen = Array(state["selected"]).map(&:to_s).uniq.sort

        chosen.present? && chosen == Array(solution["correct"]).map(&:to_s).uniq.sort
      },
      display: ->(state, params) { Widgets.join_choices(Widgets.labels_in_order(params, "options", state["selected"])) },
      solution_display: ->(solution, params) { Widgets.join_choices(Widgets.labels_in_order(params, "options", solution["correct"])) }
    ),

    # --- filling in ----------------------------------------------------------
    # One or more numeric blanks. Each is compared with ExactValue, so a student
    # may answer 3/4 where the author wrote 0,75.
    "blanks" => Definition.new(
      key: "blanks",
      checker: ->(solution, state, _params) {
        expected = solution["values"] || {}
        given = state["values"] || {}
        tolerance = solution["tolerance"]

        expected.present? && expected.all? do |field, value|
          ExactValue.equivalent?(value, given[field.to_s], tolerance: tolerance)
        end
      },
      display: ->(state, params) {
        given = state["values"] || {}
        Array(params["fields"]).map { |field| "#{field['label']} = #{given[field['id'].to_s]}" }.join(", ")
      }
    ),

    # A grid of numbers with some cells blank: magic squares, times tables,
    # function tables, cross-number puzzles.
    "grid_fill" => Definition.new(
      key: "grid_fill",
      checker: ->(solution, state, _params) {
        expected = solution["cells"] || {}
        given = state["cells"] || {}

        expected.present? && expected.all? { |cell, value| ExactValue.equivalent?(value, given[cell.to_s]) }
      },
      display: ->(state, _params) {
        (state["cells"] || {}).sort.map { |cell, value| "#{cell}: #{value}" }.join(", ")
      }
    ),

    # --- shading -------------------------------------------------------------
    "fraction_bars" => Definition.new(
      key: "fraction_bars",
      checker: ->(solution, state, _params) {
        state["shaded"].present? && state["shaded"].to_i == solution["shaded"].to_i
      },
      display: ->(state, params) { "#{state['shaded']}/#{params['segments']}" }
    ),

    # Cells on a grid. Two ways to be right: exactly these cells (a symmetry to
    # complete, a region to mark), or any cells at all as long as there are the
    # right number of them (a fraction or an area to shade).
    "grid_shade" => Definition.new(
      key: "grid_shade",
      checker: ->(solution, state, _params) {
        cells = Array(state["cells"]).map(&:to_s).uniq

        if solution["count"]
          cells.size == solution["count"].to_i
        else
          expected = Array(solution["cells"]).map(&:to_s).uniq
          expected.present? && cells.sort == expected.sort
        end
      },
      display: ->(state, _params) {
        cells = Array(state["cells"]).map(&:to_s)
        cells.empty? ? "" : "#{cells.size}: #{cells.sort.join(', ')}"
      },
      solution_display: ->(solution, params) {
        next I18n.t("widgets.grid_shade_any", count: solution["count"].to_i) if solution["count"]

        Widgets.find("grid_shade").display.call(solution, params)
      }
    )
  }.freeze

  def keys
    REGISTRY.keys
  end

  def find(key)
    REGISTRY.fetch(key.to_s) { raise ArgumentError, "Unknown widget: #{key}" }
  end

  def correct?(key, solution:, state:, params: {})
    find(key).checker.call(solution || {}, state || {}, params || {})
  end

  def display(key, state:, params: {})
    find(key).display.call(state || {}, params || {})
  end

  def solution_display(key, solution:, params: {})
    definition = find(key)
    (definition.solution_display || definition.display).call(solution || {}, params || {})
  end
end
