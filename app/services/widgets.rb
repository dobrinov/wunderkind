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

  # Item ids are written by the problem generator, and for three widgets they
  # spell out the answer: an ordering's items are s0, s1, s2 in the right order,
  # a matcher pairs l0 with r0, and a multi-select often lists the right options
  # first. The page shuffles the items, but the ids ride along in its markup, so
  # anyone reading the source could sort by them. The page therefore gets an
  # opaque token per item, keyed to the question, and the answer is translated
  # back to the real ids before it is graded or stored — so the stored state,
  # the history and every past answer keep the ids the problem file has.
  MASKED = { "ordering" => %w[items], "matcher" => %w[left right], "multi_select" => %w[options],
             "equal_parts" => %w[segments angles] }.freeze

  def mask_token(question_id, id)
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "widget:#{question_id}:#{id}")[0, 12]
  end

  def masked_params(key, params, question_id)
    lists = MASKED[key.to_s] or return params

    masked = params.merge(lists.to_h do |list|
      [ list, Array(params[list]).map { |item| item.merge("id" => mask_token(question_id, item["id"])) } ]
    end)
    # The highlighted part of an equal_parts figure is named by id too, and has
    # to reach the page as the same token as the segment or angle it names.
    masked["given"] = mask_token(question_id, params["given"]) if key.to_s == "equal_parts"
    masked
  end

  def unmask_state(key, state, params, question_id)
    lists = MASKED[key.to_s] or return state

    real = lists.flat_map { |list| Array(params[list]) }.to_h { |item| [ mask_token(question_id, item["id"]), item["id"].to_s ] }
    id = ->(token) { real.fetch(token.to_s, token.to_s) }

    case key.to_s
    when "ordering" then state.merge("order" => Array(state["order"]).map(&id))
    when "multi_select" then state.merge("selected" => Array(state["selected"]).map(&id))
    when "matcher" then state.merge("pairs" => (state["pairs"] || {}).to_h { |left, right| [ id.(left), id.(right) ] })
    when "equal_parts" then state.merge("parts" => Array(state["parts"]).map(&id))
    end
  end

  # A part of a figure by its name: "AM" for a segment, "∠ACM" for an angle.
  def part_name(params, id)
    segment = Array(params["segments"]).find { |s| s["id"].to_s == id.to_s }
    return "#{segment['from']}#{segment['to']}" if segment

    angle = Array(params["angles"]).find { |a| a["id"].to_s == id.to_s }
    angle ? "∠#{angle['from']}#{angle['vertex']}#{angle['to']}" : id.to_s
  end

  # Whether "r,c" cells fill a rectangle with these two sides, either way round.
  def rectangle?(cells, sides, corner: false)
    points = cells.map { |cell| cell.split(",").map(&:to_i) }
    return false if points.empty?

    rows, cols = points.map(&:first), points.map(&:last)
    height, width = rows.max - rows.min + 1, cols.max - cols.min + 1
    return false if corner && (rows.min != 0 || cols.min != 0)

    [ height, width ].sort == sides.map(&:to_i).sort && points.size == height * width
  end

  # The balance scale's equation after a list of moves, or nil when a move is
  # not allowed — taking more off a pan than it holds, or dividing a side that
  # does not split evenly. A side is {"x" => count, "units" => count}.
  def balance_after(params, steps)
    balance_states(params, steps)&.last
  end

  # More moves than any equation here needs; dividing by 1 is always legal, so
  # without a cap one answer could carry a million of them.
  MAX_BALANCE_STEPS = 50

  # The pans before any move and after each one, or nil when a move is refused
  # — or, with `upto_refusal`, the working as far as the refused move, which is
  # how far the page let the student get.
  def balance_states(params, steps, upto_refusal: false)
    steps = Array(steps)
    return nil if steps.size > MAX_BALANCE_STEPS && !upto_refusal

    steps = steps.first(MAX_BALANCE_STEPS)

    sides = %w[left right].map { |side| { "x" => params.dig(side, "x").to_i, "units" => params.dig(side, "units").to_i } }
    states = [ sides.map(&:dup) ]

    refused = -> { upto_refusal ? states : nil }
    steps.each do |step|
      return refused.call unless step.is_a?(Hash) && step["k"].to_s.match?(/\A\d+\z/)

      k = step["k"].to_i
      return refused.call unless k.positive?

      case step["op"].to_s
      when "units", "x"
        key = step["op"].to_s
        return refused.call unless sides.all? { |side| side[key] >= k }

        sides.each { |side| side[key] -= k }
      when "divide"
        return refused.call unless sides.all? { |side| (side["x"] % k).zero? && (side["units"] % k).zero? }

        sides.each { |side| side.transform_values! { |count| count / k } }
      else
        return refused.call
      end
      states << sides.map(&:dup)
    end

    states
  end

  # The value of x once one pan holds a single x and the other only units.
  def balance_solved(sides)
    return nil unless sides

    alone, other = sides.sort_by { |side| -side["x"] }
    alone == { "x" => 1, "units" => 0 } && other["x"].zero? ? other["units"] : nil
  end

  def balance_equation(side)
    terms = []
    terms << (side["x"] == 1 ? "x" : "#{side['x']}x") if side["x"].positive?
    terms << side["units"].to_s if side["units"].positive? || terms.empty?
    terms.join(" + ")
  end

  # Facts about a polygon drawn on the geoboard: its corners with any vertex
  # lying straight between its neighbours dropped (a rectangle drawn with a
  # point halfway along a side is still a rectangle), twice its area, its
  # perimeter, and whether its sides cross. Points are [column, row] pegs.
  # More corners than any board has pegs is not a drawing, and the crossing
  # test below is quadratic in them.
  MAX_POLYGON_POINTS = 100

  def polygon_facts(points)
    points = Array(points)
    return nil if points.size > MAX_POLYGON_POINTS
    return nil unless points.all? { |point| point.is_a?(Array) && point.size >= 2 && point.first(2).all? { |v| v.is_a?(Numeric) || v.to_s.match?(/\A-?\d+\z/) } }

    corners = points.map { |point| point.first(2).map(&:to_i) }
    corners = corners.chunk_while { |a, b| a == b }.map(&:first)
    corners.pop if corners.size > 1 && corners.first == corners.last
    # A peg is dropped only when it sits strictly between its neighbours on a
    # straight side. A peg the line turns straight back from is not "on the
    # side": dropping it hid a spike, and a doubled-back drawing was graded as
    # the triangle left over.
    corners = corners.reject.with_index do |point, i|
      before, after = corners[i - 1], corners[(i + 1) % corners.size]
      collinear = (point[0] - before[0]) * (after[1] - before[1]) == (point[1] - before[1]) * (after[0] - before[0])
      collinear && ((before[0] - point[0]) * (after[0] - point[0]) + (before[1] - point[1]) * (after[1] - point[1])).negative?
    end
    return nil if corners.size < 3 || corners.uniq.size != corners.size

    cross = ->(o, p, q) { (p[0] - o[0]) * (q[1] - o[1]) - (p[1] - o[1]) * (q[0] - o[0]) }
    on_segment = ->(p, a, b) { cross.(a, b, p).zero? && p[0].between?(*[ a[0], b[0] ].minmax) && p[1].between?(*[ a[1], b[1] ].minmax) }
    edges = corners.each_index.map { |i| [ corners[i], corners[(i + 1) % corners.size] ] }
    crossing = edges.each_with_index.to_a.combination(2).any? do |((a, b), i), ((c, d), j)|
      neighbours = (j - i).abs == 1 || (j - i).abs == edges.size - 1
      if neighbours
        # Sides meeting at a corner may only share that corner: one folding back
        # along the other is a spike.
        shared = ([ a, b ] & [ c, d ]).first
        other_one, other_two = ([ a, b ] - [ shared ]).first, ([ c, d ] - [ shared ]).first
        on_segment.(other_one, c, d) || on_segment.(other_two, a, b)
      else
        proper = (cross.(a, b, c) * cross.(a, b, d)).negative? && (cross.(c, d, a) * cross.(c, d, b)).negative?
        proper || on_segment.(c, a, b) || on_segment.(d, a, b) || on_segment.(a, c, d) || on_segment.(b, c, d)
      end
    end
    twice_area = edges.sum { |(x1, y1), (x2, y2)| x1 * y2 - x2 * y1 }.abs
    sides = edges.map { |(x1, y1), (x2, y2)| (x2 - x1)**2 + (y2 - y1)**2 }
    right = corners.each_index.all? do |i|
      before, point, after = corners[i - 1], corners[i], corners[(i + 1) % corners.size]
      (before[0] - point[0]) * (after[0] - point[0]) + (before[1] - point[1]) * (after[1] - point[1]) == 0
    end

    { corners: corners, twice_area: twice_area, perimeter: sides.sum { |square| Math.sqrt(square) },
      squared_sides: sides, simple: !crossing && twice_area.positive?, right_angles: right }
  end

  # Whether a drawn polygon is the kind of shape asked for. Every rule but the
  # shape is optional: "any triangle with area 6" leaves the perimeter open.
  def polygon_fits?(facts, solution)
    return false unless facts && facts[:simple]

    corners = facts[:corners].size
    shape_ok = case solution["shape"].to_s
    when "triangle" then corners == 3
    when "right_triangle"
      corners == 3 && facts[:squared_sides].sort.then { |a, b, c| a + b == c }
    when "rectangle" then corners == 4 && facts[:right_angles]
    when "square" then corners == 4 && facts[:right_angles] && facts[:squared_sides].uniq.size == 1
    else true
    end

    shape_ok &&
      (solution["area"].nil? || facts[:twice_area] == (solution["area"].to_r * 2)) &&
      (solution["perimeter"].nil? || (facts[:perimeter] - solution["perimeter"].to_f).abs < 1e-6)
  end

  # "x ≥ −2" from an edge, whether the edge belongs, and which way the ray runs.
  def inequality_text(state)
    return "" if state["edge"].nil? || state["direction"].blank?

    sign = state["direction"].to_s == "right" ? (state["closed"] ? "≥" : ">") : (state["closed"] ? "≤" : "<")
    "x #{sign} #{number_text(state['edge'])}"
  end

  # A number the way the problem text writes it: a decimal comma and a real
  # minus sign, and no ".0" on a whole number that arrived as a float.
  def number_text(value)
    number = value.to_f
    text = number == number.round ? number.round.to_s : number.to_s.sub(".", ",")
    text.sub(/\A-/, "−")
  end

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

    # Cells on a grid. Three ways to be right: exactly these cells (a symmetry to
    # complete, a region to mark), any cells at all as long as there are the
    # right number of them (a fraction or an area to shade), or any solid
    # rectangle of the right sides. "Правоъгълник 3 на 4" does not say which
    # side runs across, so a rectangle is accepted either way round; `corner`
    # pins it to the top-left when the text says so.
    "grid_shade" => Definition.new(
      key: "grid_shade",
      checker: ->(solution, state, _params) {
        cells = Array(state["cells"]).map(&:to_s).uniq

        if solution["rectangle"]
          Widgets.rectangle?(cells, solution["rectangle"], corner: solution["corner"])
        elsif solution["count"]
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
        if (sides = solution["rectangle"])
          next I18n.t("widgets.grid_shade_rectangle", rows: sides[0].to_i, cols: sides[1].to_i)
        end
        next I18n.t("widgets.grid_shade_any", count: solution["count"].to_i) if solution["count"]

        Widgets.find("grid_shade").display.call(solution, params)
      }
    ),

    # --- showing the working ---------------------------------------------------
    # Written addition or subtraction in columns. Only the result row is graded:
    # the small cells over each column (a carry, a borrowed digit) are the
    # student's scaffolding, stored with the answer so a parent can see where a
    # sum went wrong, but a child who carries in their head is not marked down.
    "column_arithmetic" => Definition.new(
      key: "column_arithmetic",
      checker: ->(solution, state, _params) {
        written = state["result"].to_s.gsub(/\D/, "").sub(/\A0+(?=\d)/, "")
        written.present? && written == solution["result"].to_s
      },
      display: ->(state, _params) { state["result"].to_s }
    ),

    # An equation as a balance: x boxes and unit weights on two pans. The
    # student works it by doing the same thing to both sides, then writes what x
    # is — and the written value is what is graded. The moves cannot be graded:
    # the scale only allows legal ones, so any sequence that leaves x alone is
    # right by construction and a widget nobody can get wrong measures nothing.
    # They are stored as the working, which is what a parent reads afterwards.
    "balance_scale" => Definition.new(
      key: "balance_scale",
      checker: ->(solution, state, _params) {
        state["x"].present? && ExactValue.equivalent?(solution["x"].to_s, state["x"].to_s)
      },
      display: ->(state, params) {
        equations = Widgets.balance_states(params, state["steps"], upto_refusal: true)
        chain = equations.map { |left, right| "#{Widgets.balance_equation(left)} = #{Widgets.balance_equation(right)}" }
        ends_on_x = equations.last.map { |side| Widgets.balance_equation(side) }.sort == [ state["x"].to_s, "x" ].sort
        chain << "x = #{state['x']}" if state["x"].present? && !ends_on_x
        chain.join(" → ")
      },
      solution_display: ->(solution, _params) { "x = #{solution['x']}" }
    ),

    # A polygon drawn on a pegboard by tapping its corners. Graded by rule, not
    # by position: any rectangle with area 12 and perimeter 14 is right
    # wherever it sits on the board and whichever corner it was started from.
    # The solution carries one example polygon (under "points", the shape of a
    # finished answer) for the authoring checks; the grader never reads it.
    "geoboard" => Definition.new(
      key: "geoboard",
      checker: ->(solution, state, params) {
        size = params.fetch("size", 7).to_i
        points = Array(state["points"])
        points.all? { |point| Array(point).first(2).all? { |v| v.to_i.between?(0, size - 1) } } &&
          Widgets.polygon_fits?(Widgets.polygon_facts(points), solution)
      },
      display: ->(state, _params) {
        facts = Widgets.polygon_facts(state["points"])
        next "" unless facts

        I18n.t("widgets.geoboard_display", corners: facts[:corners].size,
                                           area: Widgets.number_text(facts[:twice_area] / 2.0),
                                           perimeter: Widgets.number_text(facts[:perimeter].round(2)))
      },
      solution_display: ->(solution, _params) {
        parts = [ I18n.t("widgets.geoboard_shapes.#{solution['shape'].presence || 'polygon'}") ]
        parts << I18n.t("widgets.geoboard_area", area: Widgets.number_text(solution["area"])) if solution["area"]
        parts << I18n.t("widgets.geoboard_perimeter", perimeter: Widgets.number_text(solution["perimeter"])) if solution["perimeter"]
        parts.join(", ")
      }
    ),

    # Angles picked on the unit circle: every angle with sin α = 1/2, the angle
    # 210°, the angle in the second quadrant whose cosine is −√3/2. Compared as
    # a set and modulo 360°, so 0° and 360° are the same point.
    "unit_circle" => Definition.new(
      key: "unit_circle",
      checker: ->(solution, state, _params) {
        picked = Array(state["angles"]).map { |angle| angle.to_i % 360 }.uniq.sort
        picked.present? && picked == Array(solution["angles"]).map { |angle| angle.to_i % 360 }.uniq.sort
      },
      display: ->(state, _params) { Array(state["angles"]).map { |angle| "#{angle.to_i}°" }.join(", ") }
    ),

    # A worked solution with one wrong step; the student points at the line the
    # mistake is made on. Line 0 is the problem itself and is never the answer.
    "find_mistake" => Definition.new(
      key: "find_mistake",
      checker: ->(solution, state, _params) {
        !state["line"].nil? && state["line"].to_i == solution["line"].to_i
      },
      display: ->(state, params) {
        state["line"].nil? ? "" : Array(params["lines"])[state["line"].to_i].to_s
      }
    ),

    # Adding on an open number line in hops: 37 + 25 as +20 then +5. Both the
    # hops and the landing number are graded — the hops have to add up to the
    # change asked for, each one a size the widget offers, and the number
    # written at the end has to be where they land.
    "number_hops" => Definition.new(
      key: "number_hops",
      checker: ->(solution, state, params) {
        change = params["change"].to_i
        hops = Array(state["hops"]).map(&:to_i)
        allowed = Array(params["hops"]).map { |hop| hop.to_i.abs }

        hops.present? && hops.sum == change &&
          hops.all? { |hop| allowed.include?(hop.abs) && (hop.positive? == change.positive?) } &&
          ExactValue.equivalent?(solution["value"].to_s, state["value"].to_s)
      },
      display: ->(state, params) {
        hops = Array(state["hops"]).map { |hop| hop.to_i.negative? ? "− #{hop.to_i.abs}" : "+ #{hop}" }
        [ params["start"], *hops ].join(" ") + " = #{state['value']}"
      },
      solution_display: ->(solution, _params) { solution["value"].to_s }
    ),

    # The solutions of a one-sided inequality on a number line: where the
    # boundary is, whether it belongs (a filled or an open dot), and which way
    # the ray runs.
    "inequality_line" => Definition.new(
      key: "inequality_line",
      checker: ->(solution, state, _params) {
        !state["edge"].nil? && (state["edge"].to_f - solution["edge"].to_f).abs < 1e-9 &&
          ActiveModel::Type::Boolean.new.cast(state["closed"]) == ActiveModel::Type::Boolean.new.cast(solution["closed"]) &&
          state["direction"].to_s == solution["direction"].to_s
      },
      display: ->(state, _params) {
        Widgets.inequality_text(state.merge("closed" => ActiveModel::Type::Boolean.new.cast(state["closed"])))
      }
    ),

    # A figure with one segment or angle highlighted; the student taps every
    # part the construction makes equal to it — the other half of a segment a
    # perpendicular bisector cuts, MB once M is on the bisector of AB, the two
    # halves of a bisected angle, the angles a transversal makes equal. The
    # whole skill is noticing the equality, so the set is the answer: missing
    # one or adding one is wrong. The figure is never trustworthy by eye —
    # check.rb insists on a decoy drawn within 4% of the given part.
    "equal_parts" => Definition.new(
      key: "equal_parts",
      checker: ->(solution, state, _params) {
        tapped = Array(state["parts"]).map(&:to_s).uniq.sort
        tapped.present? && tapped == Array(solution["parts"]).map(&:to_s).uniq.sort
      },
      display: ->(state, params) {
        Array(state["parts"]).map { |id| Widgets.part_name(params, id) }.join(", ")
      },
      solution_display: ->(solution, params) {
        Array(solution["parts"]).map { |id| Widgets.part_name(params, id) }.join(", ")
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
