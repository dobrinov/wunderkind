require_relative "svg"

# Named figures, built on the Svg canvas. Each returns an Svg::Figure sized for
# the question card, which is about 560 px wide on a phone — so figures stay
# under ~380 px and rely on the 2x rasterization for sharpness.
module Figures
  module_function

  # ---------------------------------------------------------------- number ---

  # A number line with ticks, optional labels and a marked point.
  def number_line(min:, max:, step: 1, label_every: 1, point: nil, point_label: nil,
                  question_at: nil, width: 380, decimals: 0)
    left = 34.0
    right = width - 34.0
    span = (max - min).to_f
    Svg.canvas(width, 96) do |c|
      y = 52
      c.line(left - 12, y, right + 12, y, color: Svg::INK, width: 2)
      c.arrow(right, y, right + 16, y, color: Svg::INK, width: 2)
      value = min
      index = 0
      while value <= max + 1e-9
        x = left + ((value - min) / span * (right - left))
        long = (index % label_every).zero?
        c.line(x, y - (long ? 9 : 5), x, y + (long ? 9 : 5), color: Svg::INK, width: long ? 2 : 1.5)
        if long
          text = decimals.zero? ? value.round.to_s : format("%.#{decimals}f", value).tr(".", ",")
          c.text(x, y + 28, text, size: 15, color: Svg::MUTED)
        end
        value += step
        index += 1
      end
      if point
        x = left + ((point - min) / span * (right - left))
        c.dot(x, y, 6, color: Svg::ACCENT)
        c.text(x, y - 18, point_label.to_s, size: 16, color: Svg::ACCENT, weight: "700") if point_label
      end
      if question_at
        x = left + ((question_at - min) / span * (right - left))
        c.dot(x, y, 6, color: Svg::ACCENT)
        c.text(x, y - 18, "?", size: 20, color: Svg::ACCENT, weight: "700")
      end
    end
  end

  # A strip cut into equal parts, some of them shaded: fractions and percents.
  def fraction_strip(segments:, shaded:, width: 340, label: nil)
    height = label ? 112 : 92
    Svg.canvas(width, height) do |c|
      x0 = 20.0
      w = (width - 40).to_f
      part = w / segments
      segments.times do |i|
        c.rect(x0 + (i * part), 26, part, 46, fill: i < shaded ? Svg::SHADE : "#ffffff", width: 2)
      end
      c.text(width / 2.0, 96, label, size: 16, color: Svg::MUTED) if label
    end
  end

  # Two strips one under the other: equivalent fractions, comparison.
  def fraction_strips(rows:, width: 340)
    Svg.canvas(width, 40 + (rows.size * 62)) do |c|
      rows.each_with_index do |row, index|
        y = 20 + (index * 62)
        x0 = 62.0
        w = (width - 82).to_f
        part = w / row[:segments]
        row[:segments].times do |i|
          c.rect(x0 + (i * part), y, part, 42, fill: i < row[:shaded] ? Svg::SHADE : "#ffffff", width: 2)
        end
        c.text(30, y + 28, row[:label].to_s, size: 17, color: Svg::INK)
      end
    end
  end

  # A rectangle of cells, some shaded: area, fractions, percent of a hundred.
  def grid(cols:, rows:, shaded: 0, cell: 22, shaded_cells: nil, outline_only: false)
    width = (cols * cell) + 40
    height = (rows * cell) + 40
    Svg.canvas(width, height) do |c|
      count = 0
      rows.times do |ri|
        cols.times do |ci|
          filled =
            if shaded_cells
              shaded_cells.include?([ ci, ri ])
            else
              count < shaded
            end
          count += 1
          c.rect(20 + (ci * cell), 20 + (ri * cell), cell, cell,
                 fill: filled ? Svg::SHADE : "#ffffff", stroke: Svg::GRID, width: 1)
        end
      end
      c.rect(20, 20, cols * cell, rows * cell, fill: "none", width: 2.5) unless outline_only
    end
  end

  # Rows of counters, for the youngest problems: counting and multiplication.
  def dot_array(rows:, cols:, spacing: 30, radius: 10)
    width = (cols * spacing) + 40
    height = (rows * spacing) + 40
    Svg.canvas(width, height) do |c|
      rows.times do |ri|
        cols.times do |ci|
          c.dot(30 + (ci * spacing), 30 + (ri * spacing), radius, color: Svg::SHADE)
          c.circle(30 + (ci * spacing), 30 + (ri * spacing), radius, stroke: Svg::STROKE, width: 1.5)
        end
      end
    end
  end

  # A part-whole diagram: the bar model Bulgarian textbooks draw for word
  # problems.
  def tape(parts:, total_label: nil, width: 360)
    height = total_label ? 118 : 92
    Svg.canvas(width, height) do |c|
      total = parts.sum { |part| part[:size] }
      x = 24.0
      usable = (width - 48).to_f
      parts.each do |part|
        w = usable * part[:size] / total.to_f
        c.rect(x, 30, w, 44, fill: part[:fill] || Svg::FILL, width: 2)
        c.text(x + (w / 2), 58, part[:label].to_s, size: 16)
        x += w
      end
      if total_label
        c.line(24, 88, width - 24, 88, color: Svg::MUTED, width: 1.5)
        c.line(24, 82, 24, 94, color: Svg::MUTED, width: 1.5)
        c.line(width - 24, 82, width - 24, 94, color: Svg::MUTED, width: 1.5)
        c.text(width / 2.0, 110, total_label, size: 16, color: Svg::MUTED)
      end
    end
  end

  # ----------------------------------------------------------------- data ----

  def bar_chart(labels:, values:, axis_step: nil, unit: nil, highlight: nil, width: 380)
    height = 250
    base = 196.0
    top = 34.0
    max = values.max
    step = axis_step || [ 1, (max / 5.0).ceil ].max
    axis_max = ((max / step.to_f).ceil * step)
    axis_max = step if axis_max.zero?
    Svg.canvas(width, height) do |c|
      left = 46.0
      right = width - 20.0
      (0..(axis_max / step)).each do |i|
        value = i * step
        y = base - (value / axis_max.to_f * (base - top))
        c.line(left, y, right, y, color: Svg::GRID, width: 1)
        c.text(left - 10, y + 5, value.to_s, size: 14, color: Svg::MUTED, anchor: "end")
      end
      c.line(left, top - 8, left, base, color: Svg::INK, width: 2)
      c.line(left, base, right, base, color: Svg::INK, width: 2)
      slot = (right - left) / values.size
      values.each_with_index do |value, index|
        w = slot * 0.56
        x = left + (index * slot) + ((slot - w) / 2)
        h = value / axis_max.to_f * (base - top)
        fill = highlight == index ? Svg::ACCENT_FILL : Svg::FILL
        stroke = highlight == index ? Svg::ACCENT : Svg::STROKE
        c.rect(x, base - h, w, h, fill: fill, stroke: stroke, width: 2)
        c.text(x + (w / 2), base + 22, labels[index].to_s, size: 15, color: Svg::INK)
      end
      c.text(8, top - 14, unit, size: 14, color: Svg::MUTED, anchor: "start") if unit
    end
  end

  def pie_chart(parts:, width: 300, legend: true)
    height = legend ? 240 + (parts.size * 26) : 232
    Svg.canvas(width, height) do |c|
      cx = width / 2.0
      cy = 120.0
      radius = 88.0
      total = parts.sum { |part| part[:value] }
      angle = 90.0
      colors = [ "#c7d2fe", "#a5b4fc", "#818cf8", "#6366f1", "#4f46e5", "#e0e7ff" ]
      parts.each_with_index do |part, index|
        sweep = part[:value] / total.to_f * 360
        c.sector(cx, cy, radius, angle, angle - sweep, fill: part[:fill] || colors[index % colors.size])
        mid = angle - (sweep / 2)
        lx, ly = c.polar(cx, cy, radius * 0.62, mid)
        c.text(lx, ly + 5, part[:inner].to_s, size: 15, color: Svg::INK) if part[:inner]
        angle -= sweep
      end
      if legend
        parts.each_with_index do |part, index|
          y = 244 + (index * 26)
          c.rect(30, y - 12, 16, 16, fill: part[:fill] || colors[index % colors.size], stroke: Svg::MUTED, width: 1)
          c.text(56, y + 1, part[:label].to_s, size: 15, anchor: "start")
        end
      end
    end
  end

  # A spinner: the probability figure that is not a die or a coin.
  def spinner(sectors:, width: 260)
    Svg.canvas(width, 236) do |c|
      cx = width / 2.0
      cy = 124.0
      radius = 96.0
      total = sectors.size
      colors = { "red" => "#fecaca", "blue" => "#bfdbfe", "green" => "#bbf7d0",
                 "yellow" => "#fef08a", "white" => "#ffffff", "grey" => "#e5e7eb" }
      sectors.each_with_index do |sector, index|
        a1 = 90 - (index * 360.0 / total)
        a2 = a1 - (360.0 / total)
        c.sector(cx, cy, radius, a1, a2, fill: colors.fetch(sector[:color], "#e0e7ff"), width: 2)
        lx, ly = c.polar(cx, cy, radius * 0.66, (a1 + a2) / 2)
        c.text(lx, ly + 5, sector[:label].to_s, size: 15)
      end
      c.circle(cx, cy, radius, width: 2.5)
      c.dot(cx, cy, 6, color: Svg::INK)
      # A fixed pointer at the top, rather than a needle: a drawn needle would
      # look like the spin has already happened.
      c.polygon([ [ cx - 10, cy - radius - 6 ], [ cx + 10, cy - radius - 6 ], [ cx, cy - radius + 14 ] ],
                fill: Svg::INK, stroke: Svg::INK, width: 1)
    end
  end

  # A data table — statistics questions need one that is not a chart.
  def table(headers:, rows:, width: 360)
    height = 40 + ((rows.size + 1) * 34)
    Svg.canvas(width, height) do |c|
      cols = headers.size
      col_w = (width - 40).to_f / cols
      ([ headers ] + rows).each_with_index do |row, ri|
        y = 20 + (ri * 34)
        row.each_with_index do |cell, ci|
          c.rect(20 + (ci * col_w), y, col_w, 34,
                 fill: ri.zero? ? "#eef2ff" : "#ffffff", stroke: Svg::GRID, width: 1)
          c.text(20 + (ci * col_w) + (col_w / 2), y + 23, cell.to_s,
                 size: 15, weight: ri.zero? ? "700" : "400")
        end
      end
      c.rect(20, 20, col_w * cols, (rows.size + 1) * 34, fill: "none", width: 2)
    end
  end

  # A clock face: telling the time is arithmetic with a modulus.
  def clock(hours:, minutes:, width: 220)
    Svg.canvas(width, 220) do |c|
      cx = width / 2.0
      cy = 110.0
      radius = 92.0
      c.circle(cx, cy, radius, fill: "#ffffff", width: 3)
      (1..12).each do |hour|
        angle = 90 - (hour * 30)
        tx, ty = c.polar(cx, cy, radius - 27, angle)
        c.text(tx, ty + 6, hour.to_s, size: 16, color: Svg::INK)
        ox, oy = c.polar(cx, cy, radius - 6, angle)
        ix, iy = c.polar(cx, cy, radius - 12, angle)
        c.line(ix, iy, ox, oy, color: Svg::MUTED, width: 2)
      end
      minute_angle = 90 - (minutes * 6)
      hour_angle = 90 - (((hours % 12) + (minutes / 60.0)) * 30)
      hx, hy = c.polar(cx, cy, radius * 0.52, hour_angle)
      mx, my = c.polar(cx, cy, radius * 0.78, minute_angle)
      c.line(cx, cy, hx, hy, color: Svg::INK, width: 5)
      c.line(cx, cy, mx, my, color: Svg::STROKE, width: 3.5)
      c.dot(cx, cy, 5, color: Svg::INK)
    end
  end

  # ------------------------------------------------------------- geometry ---

  # Scales a set of maths-orientation points (y up) into the canvas, y down.
  def fit(points, width, height, margin: 34)
    xs = points.map(&:first)
    ys = points.map(&:last)
    span_x = [ xs.max - xs.min, 0.001 ].max
    span_y = [ ys.max - ys.min, 0.001 ].max
    scale = [ (width - (2 * margin)) / span_x, (height - (2 * margin)) / span_y ].min
    offset_x = (width - (span_x * scale)) / 2
    offset_y = (height - (span_y * scale)) / 2
    points.map do |x, y|
      [ offset_x + ((x - xs.min) * scale), height - offset_y - ((y - ys.min) * scale) ]
    end
  end

  def centroid(points)
    [ points.sum(&:first) / points.size.to_f, points.sum(&:last) / points.size.to_f ]
  end

  # Pushes a point away from the middle of the figure, so a label sits outside.
  def outward(point, centre, distance)
    dx = point[0] - centre[0]
    dy = point[1] - centre[1]
    len = Math.sqrt((dx * dx) + (dy * dy))
    len.zero? ? point : [ point[0] + (dx / len * distance), point[1] + (dy / len * distance) ]
  end

  # The workhorse triangle. `sides` are drawing proportions (a = BC, b = CA,
  # c = AB) — they only set the shape, the labels say what the lengths are.
  def triangle(sides: [ 5, 4, 6 ], vertices: %w[A B C], side_labels: {}, angle_labels: {},
               right_at: nil, ticks: {}, height_to: nil, width: 340, height: 220, fill: Svg::FILL)
    a, b, c = sides.map(&:to_f)
    x = ((b * b) + (c * c) - (a * a)) / (2 * c)
    y = Math.sqrt([ (b * b) - (x * x), 0.01 ].max)
    Svg.canvas(width, height) do |canvas|
      pa, pb, pc = fit([ [ 0, 0 ], [ c, 0 ], [ x, y ] ], width, height)
      canvas.polygon([ pa, pb, pc ], fill: fill)
      middle = centroid([ pa, pb, pc ])
      points = { vertices[0] => pa, vertices[1] => pb, vertices[2] => pc }

      if height_to
        foot = [ pc[0], pa[1] ]
        canvas.line(pc[0], pc[1], foot[0], foot[1], color: Svg::MUTED, width: 2, dash: "6 5")
        canvas.right_angle(foot, pc, pa, size: 11)
        canvas.text(pc[0] + 20, (pc[1] + foot[1]) / 2, height_to.to_s, size: 16, color: Svg::MUTED)
      end

      { [ 0, 1 ] => [ pa, pb ], [ 1, 2 ] => [ pb, pc ], [ 2, 0 ] => [ pc, pa ] }.each do |(i, j), (p1, p2)|
        key = "#{vertices[i]}#{vertices[j]}"
        alt = "#{vertices[j]}#{vertices[i]}"
        label = side_labels[key] || side_labels[alt]
        mid = [ (p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2 ]
        spot = outward(mid, middle, 22)
        canvas.text(spot[0], spot[1] + 5, label, size: 16, color: Svg::MUTED) if label
        count = ticks[key] || ticks[alt]
        canvas.ticks(p1, p2, count: count) if count
      end

      angle_labels.each do |vertex, label|
        others = points.reject { |name, _| name.to_s == vertex.to_s }.values
        canvas.angle_mark(points[vertex.to_s], others[0], others[1], label: label.to_s,
                          radius: 28, color: label.to_s.include?("?") ? Svg::ACCENT : Svg::STROKE)
      end

      if right_at
        others = points.reject { |name, _| name.to_s == right_at.to_s }.values
        canvas.right_angle(points[right_at.to_s], others[0], others[1])
      end

      points.each do |name, point|
        spot = outward(point, middle, 18)
        canvas.text(spot[0], spot[1] + 6, name, size: 17)
      end
    end
  end

  # A quadrilateral from maths-orientation points, with the same labelling kit.
  def quad(points:, vertices: %w[A B C D], side_labels: {}, angle_labels: {},
           right_angles: [], height_to: nil, diagonals: false, ticks: {},
           width: 340, height: 220, fill: Svg::FILL)
    Svg.canvas(width, height) do |canvas|
      screen = fit(points, width, height)
      canvas.polygon(screen, fill: fill)
      middle = centroid(screen)
      named = vertices.each_with_index.to_h { |name, index| [ name, screen[index] ] }

      screen.each_with_index do |p1, index|
        p2 = screen[(index + 1) % screen.size]
        key = "#{vertices[index]}#{vertices[(index + 1) % vertices.size]}"
        alt = key.reverse
        label = side_labels[key] || side_labels[alt]
        mid = [ (p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2 ]
        spot = outward(mid, middle, 27)
        canvas.text(spot[0], spot[1] + 5, label, size: 16, color: Svg::MUTED) if label
        count = ticks[key] || ticks[alt]
        canvas.ticks(p1, p2, count: count) if count
      end

      if height_to
        # The height is dropped from the left end of the top edge, so it lands
        # inside a parallelogram or trapezoid instead of beside it.
        base_y = screen.map { |point| point[1] }.max
        top_y = screen.map { |point| point[1] }.min
        top_left = screen.select { |point| (point[1] - top_y).abs < 1 }.min_by(&:first)
        canvas.line(top_left[0], top_left[1], top_left[0], base_y, color: Svg::MUTED, width: 2, dash: "6 5")
        canvas.right_angle([ top_left[0], base_y ], [ top_left[0], top_left[1] ], [ top_left[0] + 40, base_y ], size: 11)
        canvas.text(top_left[0] + 9, ((top_left[1] + base_y) / 2) + 5, height_to.to_s,
                    size: 15, color: Svg::MUTED, anchor: "start")
      end

      if diagonals
        canvas.line(screen[0][0], screen[0][1], screen[2][0], screen[2][1], color: Svg::MUTED, width: 1.8, dash: "6 5")
        canvas.line(screen[1][0], screen[1][1], screen[3][0], screen[3][1], color: Svg::MUTED, width: 1.8, dash: "6 5")
      end

      angle_labels.each do |vertex, label|
        index = vertices.index(vertex.to_s)
        prev_point = screen[(index - 1) % screen.size]
        next_point = screen[(index + 1) % screen.size]
        canvas.angle_mark(screen[index], prev_point, next_point, label: label.to_s, radius: 26,
                          color: label.to_s.include?("?") ? Svg::ACCENT : Svg::STROKE)
      end

      right_angles.each do |vertex|
        index = vertices.index(vertex.to_s)
        canvas.right_angle(screen[index], screen[(index - 1) % screen.size], screen[(index + 1) % screen.size])
      end

      named.each do |name, point|
        spot = outward(point, middle, 15)
        canvas.text(spot[0], spot[1] + 6, name, size: 17)
      end
    end
  end

  def rectangle(w_label:, h_label:, proportion: 1.6, square: false, vertices: %w[A B C D], diagonal: nil, width: 320, height: 210)
    ratio = square ? 1.0 : proportion
    points = [ [ 0, 0 ], [ ratio, 0 ], [ ratio, 1 ], [ 0, 1 ] ]
    quad(points: points, vertices: vertices,
         side_labels: { "#{vertices[0]}#{vertices[1]}" => w_label, "#{vertices[1]}#{vertices[2]}" => h_label },
         right_angles: [ vertices[0] ], diagonals: !diagonal.nil?, width: width, height: height)
  end

  # An L-shaped room: the composite-area figure.
  # cut_x is how much of the width the remaining top arm keeps, cut_y how much
  # of the height the notch takes out of the right-hand side.
  def lshape(labels:, cut_x: 0.45, cut_y: 0.45, width: 330, height: 230)
    Svg.canvas(width, height) do |c|
      points = fit([ [ 0, 0 ], [ 1, 0 ], [ 1, 1 - cut_y ], [ cut_x, 1 - cut_y ], [ cut_x, 1 ], [ 0, 1 ] ], width, height)
      c.polygon(points, fill: Svg::FILL)
      pairs = [ [ 0, 1, labels[:bottom], [ 0, 22 ] ], [ 1, 2, labels[:right], [ 26, 5 ] ],
                [ 2, 3, labels[:inner_top], [ 0, -12 ] ], [ 3, 4, labels[:inner_side], [ 24, 5 ] ],
                [ 4, 5, labels[:top], [ 0, -12 ] ], [ 5, 0, labels[:left], [ -26, 5 ] ] ]
      pairs.each do |i, j, label, (dx, dy)|
        next unless label

        mid = [ (points[i][0] + points[j][0]) / 2, (points[i][1] + points[j][1]) / 2 ]
        c.text(mid[0] + dx, mid[1] + dy, label.to_s, size: 15, color: Svg::MUTED)
      end
    end
  end

  def circle_figure(label:, show: :radius, sector: nil, sector_label: nil, chord: false, width: 300, height: 230)
    Svg.canvas(width, height) do |c|
      cx = width / 2.0
      cy = height / 2.0
      radius = 82.0
      c.circle(cx, cy, radius, fill: Svg::FILL, width: 2.5)
      if sector
        c.sector(cx, cy, radius, 90, 90 - sector, fill: "#c7d2fe", width: 2)
        c.angle_mark([ cx, cy ], c.polar(cx, cy, radius, 90), c.polar(cx, cy, radius, 90 - sector),
                     label: sector_label || "#{sector}°", radius: 34, color: Svg::ACCENT)
      end
      c.dot(cx, cy, 4.5, color: Svg::INK)
      c.text(cx - 12, cy + 18, "O", size: 16)
      case show
      when :radius
        c.line(cx, cy, cx + radius, cy, color: Svg::ACCENT, width: 2.5)
        c.text(cx + (radius / 2), sector ? cy + 22 : cy - 12, label.to_s, size: 16, color: Svg::ACCENT)
      when :diameter
        c.line(cx - radius, cy, cx + radius, cy, color: Svg::ACCENT, width: 2.5)
        c.text(cx, cy - 12, label.to_s, size: 16, color: Svg::ACCENT)
      end
      if chord
        x1, y1 = c.polar(cx, cy, radius, 200)
        x2, y2 = c.polar(cx, cy, radius, 340)
        c.line(x1, y1, x2, y2, color: Svg::MUTED, width: 2)
      end
    end
  end

  # Angle pairs: vertical, supplementary, angles round a point, and two
  # parallels cut by a transversal.
  def angle_pair(kind:, known:, ask: "?", width: 340, height: 220)
    Svg.canvas(width, height) do |c|
      cx = width / 2.0
      cy = height / 2.0
      case kind
      when :vertical
        length = 130
        angle = known.to_f
        c.line(cx - length, cy, cx + length, cy, color: Svg::STROKE, width: 2.5)
        x1, y1 = c.polar(cx, cy, length, angle)
        c.line(cx - (x1 - cx), cy - (y1 - cy), x1, y1, color: Svg::STROKE, width: 2.5)
        c.angle_mark([ cx, cy ], [ cx + length, cy ], [ x1, y1 ], label: "#{known}°", radius: 40)
        c.angle_mark([ cx, cy ], [ cx - length, cy ], [ cx - (x1 - cx), cy - (y1 - cy) ], label: ask, radius: 40, color: Svg::ACCENT)
        c.dot(cx, cy, 4, color: Svg::INK)
      when :supplementary
        length = 140
        angle = known.to_f
        c.line(cx - length, cy, cx + length, cy, color: Svg::STROKE, width: 2.5)
        x1, y1 = c.polar(cx, cy, length, angle)
        c.line(cx, cy, x1, y1, color: Svg::STROKE, width: 2.5)
        c.angle_mark([ cx, cy ], [ cx + length, cy ], [ x1, y1 ], label: "#{known}°", radius: 42)
        c.angle_mark([ cx, cy ], [ x1, y1 ], [ cx - length, cy ], label: ask, radius: 60, color: Svg::ACCENT)
        c.dot(cx, cy, 4, color: Svg::INK)
      when :around_point
        radius = 120
        angles = known
        start = 90.0
        angles.each_with_index do |(label, size), index|
          a1 = start
          a2 = start - size
          x1, y1 = c.polar(cx, cy, radius, a1)
          c.line(cx, cy, x1, y1, color: Svg::STROKE, width: 2.5)
          c.angle_mark([ cx, cy ], c.polar(cx, cy, radius, a1), c.polar(cx, cy, radius, a2),
                       label: label.to_s, radius: 44 + (index.even? ? 0 : 16),
                       color: label.to_s.include?("?") ? Svg::ACCENT : Svg::STROKE)
          start = a2
        end
        c.dot(cx, cy, 4, color: Svg::INK)
      when :transversal
        # Two parallels cut by a transversal, corresponding angles marked at
        # both crossings. x = cx + slope * (y - cy) keeps the line and the
        # crossing points consistent.
        slope = 0.5
        top = cy - 50
        bottom = cy + 50
        c.line(26, top, width - 26, top, color: Svg::STROKE, width: 2.5)
        c.line(26, bottom, width - 26, bottom, color: Svg::STROKE, width: 2.5)
        c.text(width - 14, top - 8, "a", size: 15, color: Svg::MUTED)
        c.text(width - 14, bottom - 8, "b", size: 15, color: Svg::MUTED)
        reach = 96
        c.line(cx - (slope * reach), cy - reach, cx + (slope * reach), cy + reach, color: Svg::MUTED, width: 2.5)
        upper = [ cx - (slope * 50), top ]
        lower = [ cx + (slope * 50), bottom ]
        down = [ cx + (slope * reach), cy + reach ]
        c.angle_mark(upper, [ width - 26, top ], down, label: "#{known}°", radius: 34)
        c.angle_mark(lower, [ width - 26, bottom ], down, label: ask, radius: 34, color: Svg::ACCENT)
        c.dot(upper[0], upper[1], 4, color: Svg::INK)
        c.dot(lower[0], lower[1], 4, color: Svg::INK)
      end
    end
  end

  # A single angle drawn from two rays: classify it, or read it off.
  def angle_figure(degrees:, label: nil, width: 300, height: 210)
    Svg.canvas(width, height) do |c|
      length = 130.0
      # Obtuse angles open to the left, so the vertex moves right by however
      # much the second ray needs.
      vx = 60.0 + [ 0.0, -Math.cos(degrees * Math::PI / 180) * length ].max
      vy = height - 46.0
      c.line(vx, vy, vx + length, vy, color: Svg::STROKE, width: 2.5)
      x1, y1 = c.polar(vx, vy, length, degrees)
      c.line(vx, vy, x1, y1, color: Svg::STROKE, width: 2.5)
      c.angle_mark([ vx, vy ], [ vx + length, vy ], [ x1, y1 ], label: label || "?", radius: 46,
                   color: label ? Svg::STROKE : Svg::ACCENT)
      c.dot(vx, vy, 4.5, color: Svg::INK)
      c.text(vx - 14, vy + 6, "O", size: 16)
    end
  end

  def regular_polygon(sides:, label: nil, highlight_angle: false, width: 300, height: 240)
    Svg.canvas(width, height) do |c|
      cx = width / 2.0
      cy = (height / 2.0) + 4
      radius = 88.0
      points = (0...sides).map do |index|
        angle = 90 + (index * 360.0 / sides)
        c.polar(cx, cy, radius, angle)
      end
      c.polygon(points, fill: Svg::FILL)
      if highlight_angle
        c.angle_mark(points[0], points[1], points[-1], label: "?", radius: 30, color: Svg::ACCENT)
      end
      c.text(cx, height - 8, label.to_s, size: 15, color: Svg::MUTED) if label
    end
  end

  # Two triangles of the same shape, different size: similarity and scale.
  def similar_triangles(small:, large:, labels:, width: 380, height: 220)
    Svg.canvas(width, height) do |c|
      base_y = height - 42
      left = 34.0
      gap = 46.0
      [ [ left, small, labels[:small] ], [ left + small[0] + gap, large, labels[:large] ] ].each do |x0, size, marks|
        w = size[0].to_f
        h = size[1].to_f
        apex = [ x0 + (w * 0.34), base_y - h ]
        c.polygon([ [ x0, base_y ], [ x0 + w, base_y ], apex ], fill: Svg::FILL)
        c.text(x0 + (w / 2), base_y + 24, marks[:base].to_s, size: 15, color: Svg::MUTED)
        mid = [ (x0 + apex[0]) / 2, (base_y + apex[1]) / 2 ]
        colour = marks[:side].to_s.include?("?") ? Svg::ACCENT : Svg::MUTED
        c.text(mid[0] - 16, mid[1], marks[:side].to_s, size: 15, color: colour, anchor: "end")
        c.text(x0 + (w * 0.52), base_y - (h * 0.32), marks[:name].to_s, size: 15)
      end
    end
  end

  # Collinear segments with their lengths: the "how long is AD" figure.
  def segments(points:, width: 360)
    Svg.canvas(width, 120) do |c|
      total = points.sum { |part| part[:size] }
      x = 30.0
      usable = (width - 60).to_f
      y = 60.0
      c.line(x, y, x + usable, y, color: Svg::STROKE, width: 3)
      c.dot(x, y, 5, color: Svg::INK)
      c.text(x, y - 20, points.first[:from].to_s, size: 16)
      points.each do |part|
        w = usable * part[:size] / total.to_f
        c.dot(x + w, y, 5, color: Svg::INK)
        c.text(x + w, y - 20, part[:to].to_s, size: 16)
        c.text(x + (w / 2), y + 26, part[:label].to_s, size: 15, color: part[:label].to_s.include?("?") ? Svg::ACCENT : Svg::MUTED)
        x += w
      end
    end
  end

  # ------------------------------------------------------- coordinate plane ---

  # A plane with axes, an optional line or parabola, and marked points.
  # `line` is { a:, b: } for y = ax + b; `parabola` is { a:, b:, c: }.
  def plane(x_range: (-5..5), y_range: (-5..5), points: [], line: nil, parabola: nil,
            step: 1, width: 320, height: 300, ask: nil)
    Svg.canvas(width, height) do |c|
      margin = 26.0
      x_span = (x_range.max - x_range.min).to_f
      y_span = (y_range.max - y_range.min).to_f
      sx = ->(x) { margin + ((x - x_range.min) / x_span * (width - (2 * margin))) }
      sy = ->(y) { height - margin - ((y - y_range.min) / y_span * (height - (2 * margin))) }

      x_range.step(step) do |x|
        c.line(sx.call(x), margin - 6, sx.call(x), height - margin + 6, color: Svg::GRID, width: 1)
      end
      y_range.step(step) do |y|
        c.line(margin - 6, sy.call(y), width - margin + 6, sy.call(y), color: Svg::GRID, width: 1)
      end
      c.line(margin - 10, sy.call(0), width - margin + 10, sy.call(0), color: Svg::INK, width: 2)
      c.line(sx.call(0), height - margin + 10, sx.call(0), margin - 10, color: Svg::INK, width: 2)
      c.text(width - 14, sy.call(0) - 8, "x", size: 14, color: Svg::MUTED)
      c.text(sx.call(0) + 14, margin - 4, "y", size: 14, color: Svg::MUTED)
      x_range.step(step * 2) do |x|
        next if x.zero?

        c.text(sx.call(x), sy.call(0) + 18, x.to_s, size: 12, color: Svg::MUTED)
      end
      y_range.step(step * 2) do |y|
        next if y.zero?

        c.text(sx.call(0) - 12, sy.call(y) + 4, y.to_s, size: 12, color: Svg::MUTED, anchor: "end")
      end

      if line
        ys = [ (line[:a] * x_range.min) + line[:b], (line[:a] * x_range.max) + line[:b] ]
        c.line(sx.call(x_range.min), sy.call(ys[0].clamp(y_range.min, y_range.max)),
               sx.call(x_range.max), sy.call(ys[1].clamp(y_range.min, y_range.max)),
               color: Svg::STROKE, width: 2.5)
      end

      if parabola
        samples = []
        x = x_range.min.to_f
        while x <= x_range.max
          y = (parabola[:a] * x * x) + (parabola[:b] * x) + parabola[:c]
          samples << [ sx.call(x), sy.call(y) ] if y.between?(y_range.min, y_range.max)
          x += 0.1
        end
        c.polyline(samples, stroke: Svg::STROKE, width: 2.5) if samples.size > 1
      end

      points.each do |x, y, label|
        c.dot(sx.call(x), sy.call(y), 6, color: Svg::ACCENT)
        c.text(sx.call(x) + 12, sy.call(y) - 10, label.to_s, size: 15, color: Svg::ACCENT, anchor: "start") if label
      end

      c.text(width / 2.0, height - 6, ask.to_s, size: 14, color: Svg::MUTED) if ask
    end
  end

  # ------------------------------------------------------------- solids -----

  # A cuboid in the usual schoolbook projection: front face plus an offset back
  # face. `labels` names the three edges meeting at the front-bottom-left.
  def cuboid(labels: {}, cube: false, width: 320, height: 240)
    Svg.canvas(width, height) do |c|
      w = cube ? 130.0 : 170.0
      h = cube ? 130.0 : 105.0
      d = 52.0
      x = 48.0
      y = height - 60.0
      front = [ [ x, y ], [ x + w, y ], [ x + w, y - h ], [ x, y - h ] ]
      shift = ->(point) { [ point[0] + d, point[1] - (d * 0.62) ] }
      back = front.map(&shift)
      c.polygon([ front[3], back[3], back[2], front[2] ], fill: "#e0e7ff")
      c.polygon([ front[1], back[1], back[2], front[2] ], fill: "#c7d2fe")
      c.polygon(front, fill: Svg::FILL)
      c.line(back[0][0], back[0][1], back[1][0], back[1][1], color: Svg::STROKE, width: 1.6, dash: "6 5")
      c.line(back[0][0], back[0][1], back[3][0], back[3][1], color: Svg::STROKE, width: 1.6, dash: "6 5")
      c.line(front[0][0], front[0][1], back[0][0], back[0][1], color: Svg::STROKE, width: 1.6, dash: "6 5")
      c.text(x + (w / 2), y + 26, labels[:a].to_s, size: 16, color: Svg::MUTED) if labels[:a]
      c.text(x - 12, y - (h / 2) + 5, labels[:c].to_s, size: 16, color: Svg::MUTED, anchor: "end") if labels[:c]
      c.text(x + w + (d / 2) + 16, y - (d * 0.31) + 18, labels[:b].to_s, size: 16, color: Svg::MUTED) if labels[:b]
    end
  end

  def cylinder(labels: {}, width: 260, height: 250)
    Svg.canvas(width, height) do |c|
      cx = width / 2.0
      top = 54.0
      bottom = height - 46.0
      rx = 64.0
      ry = 20.0
      c.rect(cx - rx, top, rx * 2, bottom - top, fill: Svg::FILL, stroke: "none", width: 0)
      c.line(cx - rx, top, cx - rx, bottom, color: Svg::STROKE, width: 2.5)
      c.line(cx + rx, top, cx + rx, bottom, color: Svg::STROKE, width: 2.5)
      c.ellipse(cx, bottom, rx, ry, fill: "none", width: 2.5)
      c.ellipse(cx, top, rx, ry, fill: "#e0e7ff", width: 2.5)
      c.line(cx, top, cx + rx, top, color: Svg::ACCENT, width: 2)
      c.text(cx + (rx / 2), top + 18, labels[:r].to_s, size: 15, color: Svg::ACCENT) if labels[:r]
      c.text(cx + rx + 24, (top + bottom) / 2, labels[:h].to_s, size: 15, color: Svg::MUTED) if labels[:h]
    end
  end

  def cone(labels: {}, width: 260, height: 250)
    Svg.canvas(width, height) do |c|
      cx = width / 2.0
      apex = [ cx, 40.0 ]
      bottom = height - 50.0
      rx = 66.0
      ry = 20.0
      c.polygon([ apex, [ cx - rx, bottom ], [ cx + rx, bottom ] ], fill: Svg::FILL, width: 2.5)
      c.ellipse(cx, bottom, rx, ry, fill: "#e0e7ff", width: 2.5)
      c.line(cx, bottom, cx + rx, bottom, color: Svg::ACCENT, width: 2)
      c.line(cx, apex[1], cx, bottom, color: Svg::MUTED, width: 1.8, dash: "6 5")
      c.text(cx + (rx / 2), bottom + 34, labels[:r].to_s, size: 15, color: Svg::ACCENT) if labels[:r]
      c.text(cx - 12, (apex[1] + bottom) / 2 + 20, labels[:h].to_s, size: 15, color: Svg::MUTED, anchor: "end") if labels[:h]
      c.text(cx + 40, (apex[1] + bottom) / 2, labels[:l].to_s, size: 15, color: Svg::MUTED) if labels[:l]
    end
  end

  def sphere(labels: {}, width: 240, height: 230)
    Svg.canvas(width, height) do |c|
      cx = width / 2.0
      cy = height / 2.0
      radius = 84.0
      c.circle(cx, cy, radius, fill: Svg::FILL, width: 2.5)
      c.ellipse(cx, cy, radius, 24, fill: "none", stroke: Svg::MUTED, width: 1.6, dash: "6 5")
      c.line(cx, cy, cx + radius, cy, color: Svg::ACCENT, width: 2)
      c.dot(cx, cy, 4, color: Svg::INK)
      c.text(cx + (radius / 2), cy - 10, labels[:r].to_s, size: 15, color: Svg::ACCENT) if labels[:r]
    end
  end

  # A prism or a pyramid on a triangular or square base.
  def solid(kind:, labels: {}, width: 330, height: 250)
    Svg.canvas(width, height) do |c|
      base_y = height - 54.0
      case kind
      when :prism
        w = 150.0
        h = 96.0
        d = 46.0
        x = 54.0
        front = [ [ x, base_y ], [ x + w, base_y ], [ x + (w / 2), base_y - h ] ]
        back = front.map { |px, py| [ px + d, py - (d * 0.6) ] }
        c.polygon([ front[1], back[1], back[2], front[2] ], fill: "#c7d2fe")
        c.polygon([ front[2], back[2], back[0], front[0] ], fill: "#e0e7ff")
        c.polygon(front, fill: Svg::FILL)
        c.line(back[0][0], back[0][1], back[1][0], back[1][1], color: Svg::STROKE, width: 1.6, dash: "6 5")
        c.line(front[0][0], front[0][1], back[0][0], back[0][1], color: Svg::STROKE, width: 1.6, dash: "6 5")
        c.text(x + (w / 2), base_y + 26, labels[:a].to_s, size: 15, color: Svg::MUTED) if labels[:a]
        c.text(x + w + (d / 2) + 26, base_y - (d * 0.3) + 20, labels[:h].to_s, size: 15, color: Svg::MUTED) if labels[:h]
      when :pyramid
        w = 150.0
        d = 52.0
        x = 60.0
        apex = [ x + (w / 2) + (d / 2), base_y - 130 ]
        b1 = [ x, base_y ]
        b2 = [ x + w, base_y ]
        b3 = [ x + w + d, base_y - (d * 0.6) ]
        b4 = [ x + d, base_y - (d * 0.6) ]
        c.polygon([ b1, b2, b3, b4 ], fill: "#e0e7ff")
        c.polygon([ b1, b2, apex ], fill: Svg::FILL)
        c.polygon([ b2, b3, apex ], fill: "#c7d2fe")
        c.line(b4[0], b4[1], b1[0], b1[1], color: Svg::STROKE, width: 1.6, dash: "6 5")
        c.line(b4[0], b4[1], b3[0], b3[1], color: Svg::STROKE, width: 1.6, dash: "6 5")
        c.line(b4[0], b4[1], apex[0], apex[1], color: Svg::STROKE, width: 1.6, dash: "6 5")
        centre = [ (b1[0] + b3[0]) / 2, (b1[1] + b3[1]) / 2 ]
        c.line(apex[0], apex[1], centre[0], centre[1], color: Svg::MUTED, width: 1.8, dash: "5 4")
        c.text(x + (w / 2), base_y + 26, labels[:a].to_s, size: 15, color: Svg::MUTED) if labels[:a]
        c.text(apex[0] + 12, (apex[1] + centre[1]) / 2, labels[:h].to_s, size: 15, color: Svg::MUTED, anchor: "start") if labels[:h]
      end
    end
  end

  # The unfolded box: surface area without the projection.
  def cuboid_net(labels: {}, width: 340, height: 250)
    Svg.canvas(width, height) do |c|
      a = 74.0
      b = 52.0
      h = 58.0
      x = 40.0
      y = 54.0
      c.rect(x + b, y, a, b, fill: "#e0e7ff", width: 2)
      c.rect(x, y + b, b, h, fill: Svg::FILL, width: 2)
      c.rect(x + b, y + b, a, h, fill: Svg::FILL, width: 2)
      c.rect(x + b + a, y + b, b, h, fill: Svg::FILL, width: 2)
      c.rect(x + b + a + b, y + b, a, h, fill: Svg::FILL, width: 2)
      c.rect(x + b, y + b + h, a, b, fill: "#e0e7ff", width: 2)
      c.text(x + b + (a / 2), y + b + (h / 2) + 5, labels[:face].to_s, size: 14, color: Svg::MUTED) if labels[:face]
      c.text(x + b + (a / 2), y + b + h + b + 24, labels[:a].to_s, size: 15, color: Svg::MUTED) if labels[:a]
      c.text(x - 10, y + b + (h / 2), labels[:h].to_s, size: 15, color: Svg::MUTED, anchor: "end") if labels[:h]
      c.text(x + b + a + (b / 2), y + b - 10, labels[:b].to_s, size: 15, color: Svg::MUTED) if labels[:b]
    end
  end

  # ------------------------------------------------------------- other ------

  def venn(left:, both:, right:, labels:, outside: nil, width: 340, height: 220)
    Svg.canvas(width, height) do |c|
      cy = 104.0
      radius = 76.0
      c.circle(width / 2.0 - 44, cy, radius, fill: "#e0e7ff88", width: 2.5)
      c.circle(width / 2.0 + 44, cy, radius, fill: "#c7d2fe88", width: 2.5)
      c.text(width / 2.0 - 78, cy + 6, left.to_s, size: 17)
      c.text(width / 2.0, cy + 6, both.to_s, size: 17)
      c.text(width / 2.0 + 78, cy + 6, right.to_s, size: 17)
      c.text(width / 2.0 - 96, 30, labels[0].to_s, size: 15, color: Svg::MUTED)
      c.text(width / 2.0 + 96, 30, labels[1].to_s, size: 15, color: Svg::MUTED)
      c.text(width - 20, height - 12, outside.to_s, size: 15, color: Svg::MUTED, anchor: "end") if outside
    end
  end

  # A growing pattern: three or four terms drawn, the next one asked for.
  def pattern(terms:, kind: :squares, width: 380, height: 150)
    Svg.canvas(width, height) do |c|
      slot = (width - 30) / (terms.size + 1).to_f
      cell = 13.0
      terms.each_with_index do |count, index|
        x0 = 24 + (index * slot)
        case kind
        when :squares
          side = Math.sqrt(count).round
          side.times do |ri|
            side.times do |ci|
              c.rect(x0 + (ci * cell), 84 - (ri * cell), cell, cell, fill: Svg::SHADE, stroke: Svg::STROKE, width: 1)
            end
          end
        when :dots
          rows = (count / 2.0).ceil
          count.times do |i|
            c.dot(x0 + ((i % 2) * 20), 84 - ((i / 2) * 20), 7, color: Svg::SHADE)
          end
          rows
        when :bars
          c.rect(x0, 84 - (count * 8), 26, count * 8, fill: Svg::SHADE, stroke: Svg::STROKE, width: 1.5)
        end
        c.text(x0 + 16, 122, "#{index + 1}.", size: 15, color: Svg::MUTED)
      end
      x0 = 24 + (terms.size * slot)
      c.text(x0 + 16, 78, "?", size: 30, color: Svg::ACCENT, weight: "700")
      c.text(x0 + 16, 122, "#{terms.size + 1}.", size: 15, color: Svg::MUTED)
    end
  end

  # A row of squares cut by dividing lines, with operation signs between them
  # and a question mark for the result: the figural-arithmetic puzzle where the
  # thing being added is a property of the picture, not a number in it.
  def square_equation(cuts:, operations:, width: 420)
    box = 66
    gap = 40
    Svg.canvas(width, 120) do |c|
      x = 22.0
      draw = lambda do |lines, vertical, label|
        c.rect(x, 26, box, box, fill: "#fdf3a7", stroke: Svg::STROKE, width: 2)
        if label
          c.text(x + (box / 2), 26 + (box / 2) + 9, "?", size: 26, weight: "800")
        else
          (1..lines).each do |index|
            offset = box * index / (lines + 1.0)
            if vertical
              c.line(x + offset, 26, x + offset, 26 + box, color: Svg::STROKE, width: 1.6)
            else
              c.line(x, 26 + offset, x + box, 26 + offset, color: Svg::STROKE, width: 1.6)
            end
          end
        end
        x += box + gap
      end

      cuts.each_with_index do |lines, index|
        draw.call(lines, index.odd?, false)
        sign = operations[index] || "="
        c.text(x - (gap / 2), 26 + (box / 2) + 8, sign, size: 26, weight: "800", color: Svg::INK)
      end
      draw.call(0, false, true)
    end
  end

  # The salmon the printed competition sheets use for ladybugs. Not in the app
  # palette because nothing else in the app is a ladybug; the ink and the grid
  # around it are the palette's.
  LADYBUG_BODY = "#f0827c"

  # One ladybug with `spots` spots (1..5), centred on (cx, cy). Drawn in the
  # order the shapes overlap: antennae, then the body over their roots, then the
  # head capping the seam, then the spots.
  def ladybug(canvas, cx, cy, spots, scale: 1.0)
    rx = 15 * scale
    ry = 18 * scale
    head_y = cy - ry + (4 * scale)
    head_r = 8.5 * scale

    [ -1, 1 ].each do |side|
      canvas.raw %(<path d="M #{(cx + (side * 2 * scale)).round(2)} #{(head_y - head_r + (3 * scale)).round(2)} ) +
                  %(Q #{(cx + (side * 2 * scale)).round(2)} #{(head_y - head_r - (11 * scale)).round(2)} ) +
                  %(#{(cx + (side * 10 * scale)).round(2)} #{(head_y - head_r - (9 * scale)).round(2)}" ) +
                  %(fill="none" stroke="#{Svg::INK}" stroke-width="#{(1.8 * scale).round(2)}" stroke-linecap="round"/>)
    end

    canvas.ellipse(cx, cy, rx, ry, fill: LADYBUG_BODY, stroke: Svg::INK, width: 2 * scale)
    canvas.line(cx, cy - ry + scale, cx, cy + ry - scale, color: Svg::INK, width: 1.8 * scale, cap: "butt")
    canvas.circle(cx, head_y, head_r, fill: "#ffffff", stroke: Svg::INK, width: 2 * scale)

    # Spots are placed as fractions of the body, symmetric where the count
    # allows and never on the seam — a spot the seam cuts in half is countable
    # as one or two.
    layout = {
      1 => [ [ -0.42, 0.05 ] ],
      2 => [ [ -0.42, -0.05 ], [ 0.42, 0.35 ] ],
      3 => [ [ -0.45, -0.28 ], [ -0.4, 0.32 ], [ 0.45, 0.05 ] ],
      4 => [ [ -0.45, -0.28 ], [ -0.45, 0.34 ], [ 0.45, -0.28 ], [ 0.45, 0.34 ] ],
      5 => [ [ -0.45, -0.3 ], [ -0.45, 0.34 ], [ 0.45, -0.3 ], [ 0.45, 0.34 ], [ 0.44, 0.02 ] ]
    }.fetch(spots)
    layout.each { |fx, fy| canvas.dot(cx + (fx * rx * 1.35), cy + (fy * ry), 3.4 * scale, color: Svg::INK) }
    canvas
  end

  # A Latin-square puzzle drawn with ladybugs instead of numerals: the type
  # competition sheets set for the youngest children, where counting spots
  # replaces reading digits.
  #
  # clues: { [row, col] => spots }, 0-indexed from the top left.
  # asked: the cells the question is about — they get a question mark.
  def ladybug_square(clues:, size: 4, asked: [], cell: 62)
    pad = 8
    side = size * cell
    Svg.canvas(side + (2 * pad), side + (2 * pad)) do |c|
      c.rect(pad, pad, side, side, fill: "#ffffff", stroke: Svg::INK, width: 2.5)
      (1...size).each do |index|
        offset = pad + (index * cell)
        c.line(offset, pad, offset, pad + side, color: Svg::INK, width: 1.8, cap: "butt")
        c.line(pad, offset, pad + side, offset, color: Svg::INK, width: 1.8, cap: "butt")
      end

      centre = lambda { |row, col| [ pad + (col * cell) + (cell / 2.0), pad + (row * cell) + (cell / 2.0) ] }
      asked.each do |row, col|
        x, y = centre.call(row, col)
        c.text(x, y + 12, "?", size: 34, color: Svg::ACCENT, weight: "800")
      end
      clues.each do |(row, col), spots|
        x, y = centre.call(row, col)
        ladybug(c, x, y, spots, scale: cell / 62.0)
      end
    end
  end

  # A staircase of unit squares — left aligned, never narrowing downwards — for
  # the path-counting problems: the kangaroo stands in А (top left) and walks
  # right and down to Б (bottom right). Drawn the way the printed competition
  # sheet draws it: thin interior lines, a bold outline wherever a square has no
  # neighbour, and an optional example path whose arrow stops at the edge of Б
  # rather than on top of her.
  #
  # widths: squares per row, top row first. blocked: [[row, col], ...], crossed
  # out. path: the squares of one legal path, drawn as an arrow through them.
  def staircase_grid(widths:, blocked: [], path: nil, cell: 46)
    pad = 16
    rows = widths.size
    target = [ rows - 1, widths.last - 1 ]
    left_of = ->(col) { pad + (col * cell) }
    top_of = ->(row) { pad + (row * cell) }
    centre = ->(row, col) { [ left_of.call(col) + (cell / 2.0), top_of.call(row) + (cell / 2.0) ] }
    present = ->(row, col) { row.between?(0, rows - 1) && col.between?(0, widths[row] - 1) }

    Svg.canvas((widths.max * cell) + (2 * pad), (rows * cell) + (2 * pad)) do |c|
      rows.times do |row|
        widths[row].times do |col|
          crossed = blocked.include?([ row, col ])
          # A crossed-out square keeps a white ground and says it with the
          # cross: the rasterizer quantizes to 32 colours, and a light grey
          # comes back as noise.
          fill = if [ row, col ] == [ 0, 0 ] then Svg::FILL
          elsif [ row, col ] == target then Svg::ACCENT_FILL
          else "#ffffff"
          end
          x = left_of.call(col)
          y = top_of.call(row)
          c.rect(x, y, cell, cell, fill: fill, stroke: Svg::GRID, width: 1.4)
          next unless crossed

          c.line(x + 9, y + 9, x + cell - 9, y + cell - 9, color: Svg::MUTED, width: 2.6)
          c.line(x + cell - 9, y + 9, x + 9, y + cell - 9, color: Svg::MUTED, width: 2.6)
        end
      end

      # The outline of the figure is every edge whose neighbouring square is
      # missing — that is what makes the steps of the staircase read as steps.
      rows.times do |row|
        widths[row].times do |col|
          x = left_of.call(col)
          y = top_of.call(row)
          c.line(x, y, x + cell, y, color: Svg::INK, width: 2.8, cap: "square") unless present.call(row - 1, col)
          c.line(x, y + cell, x + cell, y + cell, color: Svg::INK, width: 2.8, cap: "square") unless present.call(row + 1, col)
          c.line(x, y, x, y + cell, color: Svg::INK, width: 2.8, cap: "square") unless present.call(row, col - 1)
          c.line(x + cell, y, x + cell, y + cell, color: Svg::INK, width: 2.8, cap: "square") unless present.call(row, col + 1)
        end
      end

      if path.to_a.size > 1
        points = path.map { |row, col| centre.call(row, col) }
        # Trimmed a third of a square at both ends: А and Б carry a letter, and
        # the sheet also stops its arrow at the edge of the mother's square.
        trim = lambda do |from, to|
          dx = to[0] - from[0]
          dy = to[1] - from[1]
          length = Math.sqrt((dx * dx) + (dy * dy))
          [ from[0] + (dx / length * cell * 0.34), from[1] + (dy / length * cell * 0.34) ]
        end
        points[0] = trim.call(points[0], points[1])
        points[-1] = trim.call(points[-1], points[-2])
        c.polyline(points[0..-2], stroke: Svg::ACCENT, width: 2.6) if points.size > 2
        c.arrow(*points[-2], *points[-1], color: Svg::ACCENT, width: 2.6)
      end

      [ [ [ 0, 0 ], "А", Svg::STROKE ], [ target, "Б", Svg::ACCENT ] ].each do |square, label, colour|
        x, y = centre.call(*square)
        c.text(x, y + 9, label, size: 25, weight: "800", color: colour)
      end
    end
  end

  # A square cut into unit cells with a piece of it taken away: the competition
  # sheet's "how many little squares are missing" figure. The cells that are
  # left are shaded and outlined one by one; the cells that are gone are not
  # drawn at all, so only the dashed outline of the whole square says how big it
  # was — that is the whole difficulty of the type, and why a missing edge row
  # still has to be visible.
  #
  # kept: [[row, col], ...] 0-indexed from the top left. `guides` draws the
  # faint grid over the empty part, the scaffolding the lowest rungs keep.
  def punched_square(size:, kept:, guides: false, cell: 46)
    pad = 14
    side = size * cell
    Svg.canvas(side + (2 * pad), side + (2 * pad)) do |c|
      if guides
        (1...size).each do |index|
          offset = pad + (index * cell)
          c.line(offset, pad, offset, pad + side, color: Svg::GRID, width: 1.3, dash: "5 4", cap: "butt")
          c.line(pad, offset, pad + side, offset, color: Svg::GRID, width: 1.3, dash: "5 4", cap: "butt")
        end
      end
      c.rect(pad, pad, side, side, fill: "none", stroke: Svg::MUTED, width: 2, dash: "7 5")
      kept.each do |row, col|
        c.rect(pad + (col * cell), pad + (row * cell), cell, cell,
               fill: Svg::SHADE, stroke: Svg::INK, width: 2)
      end
    end
  end

  # --- polycubes -------------------------------------------------------------
  #
  # The competition sheets draw little constructions of glued unit cubes in
  # isometric projection, and so do these. A cell (x, y, z) is a unit cube;
  # +x runs down-right on the page, +y down-left, +z up, so every cube shows
  # exactly three faces — top, the +y face on the lower left, the +x face on the
  # lower right — and painting the cubes in order of x + y + z gets the occlusion
  # right, because that sum is the distance from the eye.
  # Which cubes are drawn at all: one whose +x, +y and +z neighbours are all
  # present has all three of its visible faces covered and vanishes from the
  # picture. A shape with such a cube cannot be drawn honestly in isometric —
  # the reader would count fewer cubes than it has — so the families check this
  # and pick another orientation, or another shape.
  def hidden_cubes(cells)
    cells.count do |x, y, z|
      cells.include?([ x + 1, y, z ]) && cells.include?([ x, y + 1, z ]) && cells.include?([ x, y, z + 1 ])
    end
  end

  def cube_extent(cells, edge)
    points = cells.flat_map { |x, y, z| cube_corners(x, y, z) }.map { |point| project_cube(point, edge) }
    xs = points.map(&:first)
    ys = points.map(&:last)
    [ xs.min, ys.min, xs.max - xs.min, ys.max - ys.min ]
  end

  # Draws one construction into an existing canvas with its projected bounding
  # box at (left, top).
  def draw_cubes(canvas, cells, left, top, edge)
    min_x, min_y, = cube_extent(cells, edge)
    place = lambda do |point|
      px, py = project_cube(point, edge)
      [ left + px - min_x, top + py - min_y ]
    end

    cells.sort_by { |x, y, z| x + y + z }.each do |x, y, z|
      faces = [
        [ Svg::CUBE_LEFT, [ [ x, y + 1, z ], [ x + 1, y + 1, z ], [ x + 1, y + 1, z + 1 ], [ x, y + 1, z + 1 ] ] ],
        [ Svg::CUBE_RIGHT, [ [ x + 1, y, z ], [ x + 1, y + 1, z ], [ x + 1, y + 1, z + 1 ], [ x + 1, y, z + 1 ] ] ],
        [ Svg::CUBE_TOP, [ [ x, y, z + 1 ], [ x + 1, y, z + 1 ], [ x + 1, y + 1, z + 1 ], [ x, y + 1, z + 1 ] ] ]
      ]
      faces.each do |fill, corners|
        canvas.polygon(corners.map { |corner| place.call(corner) }, fill: fill, stroke: Svg::INK, width: 1.6)
      end
    end
    canvas
  end

  # The whole plate: the two pieces above a rule, then the lettered
  # constructions in rows of `columns`. One image, because a question carries
  # one image — which is also why the choices are letters.
  def cube_choices(pieces:, candidates:, labels:, edge: 21, columns: 3, gap: 26)
    piece_boxes = pieces.map { |cells| cube_extent(cells, edge) }
    boxes = candidates.map { |cells| cube_extent(cells, edge) }
    cell_w = boxes.map { |box| box[2] }.max + gap
    cell_h = boxes.map { |box| box[3] }.max + 30
    rows = (candidates.size / columns.to_f).ceil
    pieces_w = piece_boxes.sum { |box| box[2] } + (gap * 2)
    pieces_h = piece_boxes.map { |box| box[3] }.max
    # Whole pixels: the rasterizer passes these to Chrome as a window size.
    width = ([ cell_w * [ candidates.size, columns ].min, pieces_w ].max + 20).ceil
    height = (pieces_h + 26 + (cell_h * rows) + 16).ceil

    Svg.canvas(width, height) do |c|
      x = (width - pieces_w) / 2.0
      pieces.each_with_index do |cells, index|
        box = piece_boxes[index]
        draw_cubes(c, cells, x + gap, pieces_h - box[3] + 8, edge)
        x += box[2] + gap
      end
      rule = pieces_h + 20
      c.line(14, rule, width - 14, rule, color: Svg::GRID, width: 1.6, cap: "butt")

      candidates.each_with_index do |cells, index|
        row = index / columns
        col = index % columns
        box = boxes[index]
        # A short last row is centred, so the plate does not read as a table
        # with a hole in it.
        in_row = [ candidates.size - (row * columns), columns ].min
        indent = (width - 20 - (cell_w * in_row)) / 2.0
        # Bottom aligned inside its cell, so the constructions stand on a line
        # rather than float at different heights.
        left = indent + (col * cell_w) + ((cell_w - box[2]) / 2.0) + 10
        top = rule + 12 + (row * cell_h) + (cell_h - 30 - box[3])
        draw_cubes(c, cells, left, top, edge)
        c.text(left + (box[2] / 2.0), rule + 12 + (row * cell_h) + cell_h - 8,
               "#{labels[index]})", size: 17, weight: "700", color: Svg::INK)
      end
    end
  end

  def cube_corners(x, y, z)
    [ x, x + 1 ].product([ y, y + 1 ], [ z, z + 1 ])
  end

  def project_cube(point, edge)
    x, y, z = point
    [ (x - y) * edge * 0.866, (((x + y) * 0.5) - z) * edge ]
  end

  # --- arrangements of segments ----------------------------------------------
  #
  # The "how many triangles are in the figure" plate: a shape with a few more
  # segments drawn across it, every crossing lettered so the question and the
  # worked solution can name what they mean. Coordinates come in as unit
  # fractions with y pointing up, the way the geometry is written; here they are
  # scaled and flipped once.
  #
  # nodes: [[name, [x, y], interior?], ...]; segments: [[[x, y], [x, y]], ...].
  def segment_art(nodes:, segments:, side: 232, pad: 26)
    top = nodes.map { |_, point,| point[1] }.max.to_f
    right = nodes.map { |_, point,| point[0] }.max.to_f
    place = ->(point) { [ pad + (point[0].to_f * side), pad + ((top - point[1].to_f) * side) ] }

    Svg.canvas((right * side).round + (2 * pad), (top * side).round + (2 * pad)) do |c|
      segments.each { |from, to| c.polyline([ place.call(from), place.call(to) ], stroke: Svg::STROKE, width: 2.4) }

      centre = [ right / 2.0, top / 2.0 ]
      nodes.each do |name, point, interior|
        x, y = place.call(point)
        if interior
          # A letter inside the figure sits on the lines, so it gets a white
          # disc under it and a dot to say which crossing it names.
          c.dot(x, y, 2.6, color: Svg::INK)
          c.circle(x + 12, y - 11, 9.5, fill: "#ffffff", stroke: "#ffffff", width: 0)
          c.text(x + 12, y - 5, name, size: 16, weight: "600", color: Svg::INK)
        else
          dx = point[0].to_f - centre[0]
          dy = point[1].to_f - centre[1]
          length = Math.sqrt((dx * dx) + (dy * dy))
          length = 1 if length.zero?
          c.dot(x, y, 2.6, color: Svg::INK)
          c.text(x + (dx / length * 16), y - (dy / length * 16) + 6, name, size: 16, weight: "600", color: Svg::INK)
        end
      end
    end
  end

  # A schedule chart: one lane per thing that switches on and off, drawn against
  # a minute axis — the competition sheet's lighting plan. Each lane gets its own
  # shade of the corpus indigo rather than a colour of its own: the lanes are
  # told apart by *position* and by the letter at the left, which is what a
  # printed sheet in one colour has to do anyway.
  #
  # lanes: [[label, [[from, to], ...]], ...]; span: the last mark on the axis.
  def timeline_bars(lanes:, span:, unit: "минути")
    scale = [ [ 360.0 / span, 34 ].min, 17 ].max
    left = 40.0
    lane_h = 26.0
    gap = 9.0
    top = 16.0
    plot = (lanes.size * lane_h) + ((lanes.size - 1) * gap)
    axis = top + plot + 10
    shades = [ "#a5b4fc", "#818cf8", "#6366f1", "#c7d2fe" ]
    # Every mark when they fit, every second one when they would collide.
    every = scale < 22 ? 2 : 1

    Svg.canvas((left + (span * scale) + 22).ceil, (axis + 54).ceil) do |c|
      (0..span).each do |mark|
        x = left + (mark * scale)
        c.line(x, top - 6, x, axis, color: Svg::GRID, width: 1.2, cap: "butt")
        next unless (mark % every).zero?

        c.text(x, axis + 22, mark.to_s, size: 14, color: Svg::MUTED)
      end
      c.line(left, axis, left + (span * scale), axis, color: Svg::INK, width: 2)

      lanes.each_with_index do |(label, runs), index|
        y = top + (index * (lane_h + gap))
        c.text(left - 12, y + 18, label.to_s, size: 15, weight: "600", anchor: "end")
        runs.each do |from, to|
          c.rect(left + (from * scale), y, (to - from) * scale, lane_h,
                 fill: shades[index % shades.size], stroke: Svg::INK, width: 1.6)
        end
      end
      c.text(left + (span * scale / 2.0), axis + 46, unit, size: 14, weight: "600", color: Svg::MUTED)
    end
  end

  # --- the balance ------------------------------------------------------------

  # One weight: the little jar shape the competition sheets draw, with its label
  # inside — a number, a question mark, or a letter.
  def draw_weight(canvas, x, base, label, size: 34)
    body = size
    height = size * 1.05
    top = base - height
    canvas.rect(x + (body * 0.22), top - (size * 0.2), body * 0.56, size * 0.2,
                fill: "#ffffff", stroke: Svg::INK, width: 1.8, radius: 2)
    canvas.polygon([ [ x + (body * 0.12), top ], [ x + (body * 0.88), top ],
                     [ x + body, base ], [ x, base ] ],
                   fill: "#ffffff", stroke: Svg::INK, width: 2)
    canvas.text(x + (body / 2.0), base - (height * 0.36), label.to_s, size: 16, weight: "700")
  end

  # A balanced beam: the pans hang the same distance from the fulcrum, because
  # that is what the picture claims. Each pan is a list of labels; `aside` is the
  # weight standing next to the scale.
  #
  # Labels: a number, "?" for the one the question asks about, a letter for one
  # the question refers to, "" for a weight whose value is not shown.
  def balance_scale(left:, right:, aside: nil, weight: 34)
    slot = weight + 6
    pan = ->(list) { (list.size * slot) + 18 }
    reach = ([ pan.call(left), pan.call(right) ].max / 2.0) + 26
    centre = 30 + reach + (pan.call(left) / 2.0)
    span = (centre + reach + (pan.call(right) / 2.0) + 30)
    width = (aside ? span + 74 : span + 24).ceil
    base = 96.0
    beam = base + 16

    Svg.canvas(width, 176) do |c|
      c.line(centre - reach, beam, centre + reach, beam, color: Svg::INK, width: 4, cap: "butt")
      # The fulcrum, drawn as the sheet draws it: a solid wedge under the middle.
      c.polygon([ [ centre - 22, beam + 30 ], [ centre + 22, beam + 30 ], [ centre + 9, beam ], [ centre - 9, beam ] ],
                fill: Svg::INK, stroke: Svg::INK, width: 1)

      [ [ left, centre - reach ], [ right, centre + reach ] ].each do |list, at|
        edge = at - (pan.call(list) / 2.0)
        c.line(edge, base, edge + pan.call(list), base, color: Svg::INK, width: 2.4, cap: "butt")
        # The end ticks that make a pan read as a pan and not as a shelf.
        [ edge, edge + pan.call(list) ].each { |x| c.line(x, base, x, base - 13, color: Svg::INK, width: 2.4) }
        list.each_with_index { |label, index| draw_weight(c, edge + 9 + (index * slot), base, label, size: weight) }
      end

      # The weight left out stands beside the scale, on nothing, as it does on
      # the sheet: it is not part of the balance and should not look like it is.
      draw_weight(c, span + 8, base, aside, size: weight) if aside
    end
  end

  # --- the island and its roads ----------------------------------------------

  # The compass, so "north of road A" means something on the page.
  def draw_compass(canvas, cx, cy, arm: 26)
    [ [ 0, -1, "Север", 0, -arm - 12 ], [ 0, 1, "Юг", 0, arm + 22 ],
      [ 1, 0, "Изток", arm + 30, 5 ], [ -1, 0, "Запад", -arm - 30, 5 ] ].each do |dx, dy, label, lx, ly|
      canvas.arrow(cx, cy, cx + (dx * arm), cy + (dy * arm), color: Svg::INK, width: 2.4)
      canvas.text(cx + lx, cy + ly, label, size: 14, weight: "600")
    end
  end

  # An island with roads across it, drawn the way the competition sheet draws it:
  # a blob, thick straight roads, a label along each one, and a compass beside
  # it. The houses are counted in the words, not drawn — the picture is there to
  # say which side is which.
  #
  # roads: [[label, :horizontal | :vertical, offset], ...] where the offset is a
  # fraction of the island's radius, so two parallel roads sit apart.
  # quarters: labels for the regions, keyed [band, side] — drawn only when the
  # question is about a region rather than a side.
  def island_roads(roads:, quarters: {}, seed: 1, width: 470, height: 250)
    cx = width - 150.0
    cy = height / 2.0
    radius = 118.0
    # A wobbly circle, smoothed through the midpoints of its own outline: the
    # island carries no information, so it only has to look like an island.
    steps = 14
    rng = Random.new(seed)
    ring = (0...steps).map do |index|
      angle = (index * 2 * Math::PI / steps) - (Math::PI / 2)
      reach = radius * (0.93 + (rng.rand * 0.14))
      [ cx + (Math.cos(angle) * reach * 1.16), cy + (Math.sin(angle) * reach * 0.9) ]
    end

    Svg.canvas(width, height) do |c|
      mid = ->(a, b) { [ (a[0] + b[0]) / 2.0, (a[1] + b[1]) / 2.0 ] }
      start = mid.call(ring[-1], ring[0])
      path = +"M #{start[0].round(2)} #{start[1].round(2)}"
      ring.each_with_index do |point, index|
        finish = mid.call(point, ring[(index + 1) % steps])
        path << " Q #{point[0].round(2)} #{point[1].round(2)} #{finish[0].round(2)} #{finish[1].round(2)}"
      end
      c.raw %(<path d="#{path} Z" fill="#{Svg::SHADE}" stroke="#{Svg::STROKE}" stroke-width="2"/>)

      # The label on the north-south road goes in the widest gap between the
      # east-west ones, or it lands on top of one of them.
      lanes = ([ -1.0 ] + roads.select { |_, kind,| kind == :horizontal }.map(&:last).sort + [ 1.0 ])
      gap = lanes.each_cons(2).max_by { |low, high| high - low }
      middle = (gap.first + gap.last) / 2.0

      roads.each do |label, kind, offset|
        if kind == :horizontal
          y = cy + (offset * radius)
          c.line(cx - (radius * 1.14), y + 8, cx + (radius * 1.14), y - 8, color: Svg::INK, width: 7, cap: "butt")
          c.text(cx - (radius * 0.66), y - 12, label, size: 15, weight: "700")
        else
          x = cx + (offset * radius * 1.1)
          c.line(x - 8, cy - (radius * 0.9), x + 8, cy + (radius * 0.9), color: Svg::INK, width: 7, cap: "butt")
          c.text(x - 15, cy + (middle * radius * 0.72), label, size: 15, weight: "700", rotate: -90)
        end
      end

      quarters.each { |(qx, qy), label| c.text(cx + (qx * radius * 0.62), cy + (qy * radius * 0.5), label, size: 15, weight: "700", color: Svg::INK) }
      draw_compass(c, 104, cy - 14)
    end
  end

  # --- the maze of rooms -----------------------------------------------------

  # Floor plans of a maze of rooms, one plan per storey, drawn the way a plan is
  # drawn rather than as the isometric cutaway of the competition sheet: a wall
  # is a line, a door is a gap in it, stairs are the hatched square, and a
  # sticker is its own word inside the room. The sheet's drawing is a picture of
  # a building; this is a picture of the problem, and it survives being 350
  # pixels wide on a phone.
  #
  # floors: [[caption, rows, cols], ...] — every plan the same size.
  # doors: [[floor, row, col, :east | :south], ...] the walls that are open.
  # stairs: [[floor, row, col], ...] rooms with a staircase.
  # stickers: { [floor, row, col] => "жаба" }
  # ways: [[floor, row, col, :north | :south | :east | :west, "вход"], ...]
  def maze_floors(floors:, doors:, stairs:, stickers:, ways:, cell: 62)
    # Room enough on both sides for an arrow and its label outside the wall.
    pad = 66
    gap = 46
    rows = floors.first[1]
    cols = floors.first[2]
    plan_w = cols * cell
    plan_h = rows * cell
    width = (pad * 2) + (floors.size * plan_w) + ((floors.size - 1) * gap)
    origin = ->(index) { pad + (index * (plan_w + gap)) }
    # An opening in the north wall puts its arrow and its word above the plan,
    # and one in the south wall puts them below, beside where the caption goes —
    # so the margins are as deep as the openings this maze actually has.
    above = ways.any? { |way| way[3] == :north } ? 78.0 : 30.0
    below = ways.any? { |way| way[3] == :south } ? 96.0 : 52.0

    Svg.canvas(width.ceil, (above + plan_h + below).ceil) do |c|
      floors.each_with_index do |(caption, floor_rows, floor_cols), index|
        left = origin.call(index)
        top = above
        open = ->(row, col, side) { doors.include?([ index, row, col, side ]) }
        way = ->(row, col, side) { ways.find { |f, r, cl, sd,| [ f, r, cl, sd ] == [ index, row, col, side ] } }

        # Walls, one segment at a time: skipped in the middle third where a door
        # or an outside opening is.
        wall = lambda do |x1, y1, x2, y2, opening|
          if opening
            c.line(x1, y1, x1 + ((x2 - x1) / 3.0), y1 + ((y2 - y1) / 3.0), color: Svg::INK, width: 3, cap: "butt")
            c.line(x1 + ((x2 - x1) * 2 / 3.0), y1 + ((y2 - y1) * 2 / 3.0), x2, y2, color: Svg::INK, width: 3, cap: "butt")
          else
            c.line(x1, y1, x2, y2, color: Svg::INK, width: 3, cap: "butt")
          end
        end

        floor_rows.times do |row|
          floor_cols.times do |col|
            x = left + (col * cell)
            y = top + (row * cell)
            # Every wall of every room, so the outer edge gets one too. The flag
            # says whether this wall has a *gap* in it: a door between two rooms,
            # or the way in and the way out on the boundary.
            wall.call(x, y, x + cell, y, row.zero? ? way.call(row, col, :north) : open.call(row - 1, col, :south))
            wall.call(x, y, x, y + cell, col.zero? ? way.call(row, col, :west) : open.call(row, col - 1, :east))
            wall.call(x + cell, y, x + cell, y + cell, col == floor_cols - 1 ? way.call(row, col, :east) : open.call(row, col, :east))
            wall.call(x, y + cell, x + cell, y + cell, row == floor_rows - 1 ? way.call(row, col, :south) : open.call(row, col, :south))

            if stairs.include?([ index, row, col ])
              sx = x + (cell * 0.13)
              sy = y + (cell * 0.62)
              c.rect(sx, sy, cell * 0.4, cell * 0.26, fill: Svg::FILL, stroke: Svg::INK, width: 1.4)
              4.times { |step| c.line(sx + (step * cell * 0.1) + (cell * 0.1), sy, sx + (step * cell * 0.1) + (cell * 0.1), sy + (cell * 0.26), color: Svg::INK, width: 1.2, cap: "butt") }
            end
            label = stickers[[ index, row, col ]]
            c.text(x + (cell / 2.0), y + (cell * 0.38), label, size: 11, weight: "700", color: Svg::STROKE) if label
          end
        end

        # A single plan needs no caption: naming a storey only means something
        # when there is another one to tell it from.
        # Clear of a south arrow and its word when there is one.
        c.text(left + (plan_w / 2.0), top + plan_h + (below > 52 ? 78 : 32), caption,
               size: 15, weight: "600") if caption.to_s != ""
      end

      # The way in and the way out, arrows outside the wall they open.
      ways.each do |floor, row, col, side, name, way|
        left = origin.call(floor)
        x = left + (col * cell) + (cell / 2.0)
        y = above + (row * cell) + (cell / 2.0)
        # The opening in the wall, a point out in the open beyond it, and where
        # the word goes.
        edge, outside, label_at =
          case side
          when :north then [ [ x, y - (cell / 2.0) - 3 ], [ x, y - cell - 16 ], [ x, y - cell - 24 ] ]
          when :south then [ [ x, y + (cell / 2.0) + 3 ], [ x, y + cell + 16 ], [ x, y + cell + 32 ] ]
          when :west then [ [ x - (cell / 2.0) - 3, y ], [ x - cell + 4, y ], [ x - (cell * 0.95), y - 12 ] ]
          else [ [ x + (cell / 2.0) + 3, y ], [ x + cell - 4, y ], [ x + (cell * 0.95), y - 12 ] ]
          end
        # The way in points at the wall, the way out points away from it — as the
        # printed sheet draws them, and as anyone reads an exit.
        from, to = way == :out ? [ edge, outside ] : [ outside, edge ]
        c.arrow(from[0], from[1], to[0], to[1], color: Svg::INK)
        c.text(label_at[0], label_at[1], name, size: 13, weight: "600")
      end
    end
  end

  # --- puzzle pieces ---------------------------------------------------------

  # One polyomino on squared paper: every cell outlined thinly, and a thick line
  # on every edge with no neighbour, which is what makes the shape read as one
  # piece rather than a handful of squares.
  def draw_piece(canvas, cells, left, top, cell, fill: Svg::SHADE)
    cells.each do |row, col|
      canvas.rect(left + (col * cell), top + (row * cell), cell, cell,
                  fill: fill, stroke: Svg::GRID, width: 1)
    end
    draw_piece_outline(canvas, cells, left, top, cell)
  end

  def draw_piece_outline(canvas, cells, left, top, cell)
    cells.each do |row, col|
      x = left + (col * cell)
      y = top + (row * cell)
      canvas.line(x, y, x + cell, y, color: Svg::INK, width: 2.4, cap: "square") unless cells.include?([ row - 1, col ])
      canvas.line(x, y + cell, x + cell, y + cell, color: Svg::INK, width: 2.4, cap: "square") unless cells.include?([ row + 1, col ])
      canvas.line(x, y, x, y + cell, color: Svg::INK, width: 2.4, cap: "square") unless cells.include?([ row, col - 1 ])
      canvas.line(x + cell, y, x + cell, y + cell, color: Svg::INK, width: 2.4, cap: "square") unless cells.include?([ row, col + 1 ])
    end
    canvas
  end

  # The plate for the jigsaw question: the shape to be assembled on the first
  # row, the numbered pieces on the second. The pieces sit on a common baseline
  # so their heights can be compared, which is half of what the reader is doing.
  # `placed` draws part of the board already filled in, in a darker shade: then
  # the board reads as a hole waiting for one more piece.
  def puzzle_pieces(target:, pieces:, placed: nil, cell: 24, gap: 26)
    rows, cols = target
    board = (0...rows).to_a.product((0...cols).to_a)
    widths = pieces.map { |piece| (piece.map(&:last).max + 1) * cell }
    heights = pieces.map { |piece| (piece.map(&:first).max + 1) * cell }
    # The caption gets a band of its own, or a piece is drawn over it.
    top_h = (rows * cell) + 46
    width = [ widths.sum + (gap * pieces.size) + 20, (cols * cell) + 40 ].max
    height = top_h + heights.max + 46

    Svg.canvas(width.ceil, height.ceil) do |c|
      # With a piece already in it, the board is drawn empty — white reads as a
      # hole, and the piece lying in it is the only shaded part.
      draw_piece(c, board, 20, 14, cell, fill: placed ? "#ffffff" : Svg::SHADE)
      if placed
        placed.each do |row, col|
          c.rect(20 + (col * cell), 14 + (row * cell), cell, cell,
                 fill: Svg::SHADE, stroke: Svg::GRID, width: 1)
        end
        draw_piece_outline(c, placed, 20, 14, cell)
      end
      c.text(20 + ((cols * cell) / 2.0), (rows * cell) + 34, rows == cols ? "квадратът" : "правоъгълникът",
             size: 14, weight: "600", color: Svg::MUTED)

      x = ((width - widths.sum - (gap * (pieces.size - 1))) / 2.0).clamp(14, width)
      pieces.each_with_index do |piece, index|
        base = top_h + heights.max
        draw_piece(c, piece, x, base - heights[index], cell)
        c.text(x + (widths[index] / 2.0), base + 22, (index + 1).to_s, size: 16, weight: "700")
        x += widths[index] + gap
      end
    end
  end

  # --- dots on a lattice -----------------------------------------------------

  # Squared paper with points marked on the crossings, the way the competition
  # sheet draws it: a plain grid and red dots. Coordinates count from the bottom
  # left, like the mathematics, and are flipped once here.
  def lattice_dots(cols:, rows:, dots:, cell: 40)
    pad = 20
    Svg.canvas((cols * cell) + (2 * pad), (rows * cell) + (2 * pad)) do |c|
      (0..rows).each do |row|
        y = pad + (row * cell)
        c.line(pad, y, pad + (cols * cell), y, color: Svg::INK, width: 1.6, cap: "butt")
      end
      (0..cols).each do |col|
        x = pad + (col * cell)
        c.line(x, pad, x, pad + (rows * cell), color: Svg::INK, width: 1.6, cap: "butt")
      end
      dots.each do |x, y|
        c.circle(pad + (x * cell), pad + ((rows - y) * cell), 7.5,
                 fill: Svg::ACCENT, stroke: Svg::INK, width: 1.8)
      end
    end
  end

  # A plain square of numbers with thin inner lines and a heavy border — the
  # arithmetic-puzzle square of the competition sheets. A nil cell prints as "?".
  def number_square(rows:, cell: 46)
    pad = 12
    side_w = rows.first.size * cell
    side_h = rows.size * cell
    Svg.canvas(side_w + (2 * pad), side_h + (2 * pad)) do |c|
      rows.each_with_index do |line, row|
        line.each_with_index do |value, col|
          x = pad + (col * cell)
          y = pad + (row * cell)
          c.rect(x, y, cell, cell, fill: "#ffffff", stroke: Svg::INK, width: 1.4)
          c.text(x + (cell / 2.0), y + (cell * 0.66), value.nil? ? "?" : value.to_s,
                 size: 19, weight: value.nil? ? "700" : "400",
                 color: value.nil? ? Svg::ACCENT : Svg::INK)
        end
      end
      c.rect(pad, pad, side_w, side_h, fill: "none", stroke: Svg::INK, width: 2.8)
    end
  end

  # --- dots and bars ---------------------------------------------------------

  # One numeral of the dot-and-bar kind: dots in a row above a stack of bars,
  # sitting on a common baseline so a row of them can be compared.
  def draw_dot_bar(canvas, dots, bars, left, base, unit: 16)
    width = unit * 4
    pitch = unit * 0.62
    bars.times do |index|
      y = base - (index * pitch)
      canvas.line(left, y, left + width, y, color: Svg::INK, width: unit * 0.33, cap: "butt")
    end
    return canvas if dots.zero?

    top = base - (bars * pitch) - (unit * 0.62)
    spacing = unit * 0.92
    start = left + ((width - ((dots - 1) * spacing)) / 2.0)
    dots.times { |index| canvas.dot(start + (index * spacing), top, unit * 0.36, color: Svg::INK) }
    canvas
  end

  # A row of such numerals, lettered underneath when the question is a choice
  # between them. `given` puts another row above, joined by "+" — the numbers
  # being added, above a rule, with the choices below it.
  def dot_bar_plate(symbols:, labels: nil, given: nil, unit: 16, gap: 34)
    step = (unit * 4) + gap
    row_h = (unit * 5) + 12
    width = [ symbols.size, given.to_a.size ].max * step
    width += gap
    height = row_h + (labels ? 34 : 12) + (given ? row_h + 14 : 0)

    Svg.canvas(width.ceil, height.ceil) do |c|
      row = lambda do |list, base, plus, letters|
        left = ((width - (list.size * step) + gap) / 2.0)
        list.each_with_index do |(dots, bars), index|
          x = left + (index * step)
          draw_dot_bar(c, dots, bars, x, base, unit: unit)
          c.text(x + (unit * 2), base + 30, "#{letters[index]})", size: 16, weight: "700") if letters
          next unless plus && index < list.size - 1

          c.text(x + (unit * 4) + (gap / 2.0), base - (unit * 0.5), "+", size: 22, weight: "700",
                 color: Svg::MUTED)
        end
      end

      if given
        row.call(given, (unit * 4).to_f, true, nil)
        c.line(14, row_h + 6, width - 14, row_h + 6, color: Svg::GRID, width: 1.6, cap: "butt")
      end
      row.call(symbols, (given ? row_h + 14 : 0) + (unit * 4).to_f, false, labels)
    end
  end

  # --- cross-number puzzles ---------------------------------------------------

  # A crossword of arithmetic: cells laid on a grid, each one a number, an
  # operator, a filled square, or nothing at all. `nil` means no cell — that is
  # what gives these puzzles their staircase shape — and "?" is drawn in the
  # accent colour, because it is the one the question asks about.
  def cross_number(cells:, cell: 52)
    rows = cells.size
    cols = cells.map(&:size).max
    pad = 10
    Svg.canvas((cols * cell) + (2 * pad), (rows * cell) + (2 * pad)) do |c|
      cells.each_with_index do |line, row|
        line.each_with_index do |content, col|
          next if content.nil?

          x = pad + (col * cell)
          y = pad + (row * cell)
          if content == :black
            c.rect(x, y, cell, cell, fill: Svg::INK, stroke: Svg::INK, width: 2)
            next
          end

          c.rect(x, y, cell, cell, fill: "#ffffff", stroke: Svg::INK, width: 2)
          text = content.to_s
          c.text(x + (cell / 2.0), y + (cell * 0.67), text,
                 size: text.length > 2 ? 18 : 21, weight: text == "?" ? "700" : "600",
                 color: text == "?" ? Svg::ACCENT : Svg::INK)
        end
      end
    end
  end

  # --- a square with points on its sides -------------------------------------

  # A square or rectangle lettered A B C D counter-clockwise from the bottom
  # left, with points marked along its sides and a polygon drawn between named
  # corners — the figure for "E and F are the midpoints of BC and CD, what is the
  # area of AEF". A mark at the middle of a side gets tick marks on both halves,
  # the textbook way of saying the two are equal.
  #
  # marks: { "E" => [ :bc, Rational(1, 2) ], … } along the side's own direction.
  # polygon: the letters to join, in order.
  def square_marks(marks:, polygon:, tall: 1.0, side: 210)
    pad = 30
    height = side * tall
    corners = { "A" => [ 0.0, 0.0 ], "B" => [ 1.0, 0.0 ], "C" => [ 1.0, 1.0 ], "D" => [ 0.0, 1.0 ] }
    sides = { ab: %w[A B], bc: %w[B C], cd: %w[C D], da: %w[D A] }
    place = ->(point) { [ pad + (point[0] * side), pad + ((1 - point[1]) * height) ] }

    points = corners.dup
    marks.each do |label, (where, fraction)|
      from, to = sides[where].map { |letter| corners[letter] }
      points[label] = [ from[0] + ((to[0] - from[0]) * fraction), from[1] + ((to[1] - from[1]) * fraction) ]
    end

    Svg.canvas((side + (2 * pad)).ceil, (height + (2 * pad)).ceil) do |c|
      c.polygon(%w[A B C D].map { |letter| place.call(points[letter]) }, fill: "#ffffff", width: 2.5)
      c.polygon(polygon.map { |letter| place.call(points[letter]) }, fill: Svg::FILL, stroke: Svg::INK, width: 2.5)

      marks.each do |label, (where, fraction)|
        next unless fraction == Rational(1, 2)

        from, to = sides[where].map { |letter| place.call(corners[letter]) }
        middle = place.call(points[label])
        c.ticks(from, middle, count: 1)
        c.ticks(middle, to, count: 1)
      end

      # Letters outside the figure, pushed away from its middle.
      points.each do |label, point|
        x, y = place.call(point)
        dx = point[0] - 0.5
        dy = point[1] - 0.5
        length = Math.sqrt((dx * dx) + (dy * dy))
        length = 1 if length.zero?
        c.dot(x, y, 3, color: Svg::INK) unless corners.key?(label)
        c.text(x + (dx / length * 19), y - (dy / length * 19) + 6, label, size: 16, weight: "700",
               style: "italic")
      end
    end
  end
end
