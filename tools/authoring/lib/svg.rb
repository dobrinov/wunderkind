# The figure library: every picture in the corpus is drawn here as SVG and
# rasterized to PNG by tools/authoring/rasterize.sh.
#
# Why SVG then PNG, rather than serving the SVG: Active Storage refuses to serve
# image/svg+xml inline (it is not in content_types_allowed_inline, and with
# X-Content-Type-Options: nosniff the browser will not render it in an <img>).
# Widening that setting for the whole app would also widen it for teacher
# uploads, so the corpus ships PNGs instead — the format the question importer
# and the three views that show a question image already expect.
#
# Colours follow the app's palette so a figure does not look pasted in.
module Svg
  INK = "#111827"       # labels
  MUTED = "#6b7280"     # secondary labels, tick numbers
  STROKE = "#4338ca"    # the figure itself
  FILL = "#eef2ff"      # its interior
  ACCENT = "#dc2626"    # the part the question asks about
  ACCENT_FILL = "#fee2e2"
  GRID = "#d1d5db"
  SHADE = "#a5b4fc"
  # The three faces of a unit cube, lit from the upper left.
  CUBE_TOP = "#c7d2fe"
  CUBE_LEFT = "#a5b4fc"
  CUBE_RIGHT = "#818cf8"
  FONT = "system-ui, -apple-system, Helvetica, Arial, sans-serif"

  Figure = Struct.new(:markup, :width, :height, keyword_init: true)

  # A tiny drawing surface. Coordinates are pixels, y down, like SVG itself:
  # the figures are small and hand-placed, so a projection would only get in
  # the way.
  class Canvas
    attr_reader :width, :height

    def initialize(width, height)
      @width = width
      @height = height
      @parts = []
    end

    def raw(markup)
      @parts << markup
      self
    end

    def line(x1, y1, x2, y2, color: STROKE, width: 2.5, dash: nil, cap: "round")
      raw %(<line x1="#{r x1}" y1="#{r y1}" x2="#{r x2}" y2="#{r y2}" stroke="#{color}" stroke-width="#{width}" stroke-linecap="#{cap}"#{dash_attr(dash)}/>)
    end

    def polygon(points, fill: FILL, stroke: STROKE, width: 2.5, dash: nil)
      raw %(<polygon points="#{points.map { |x, y| "#{r x},#{r y}" }.join(' ')}" fill="#{fill}" stroke="#{stroke}" stroke-width="#{width}" stroke-linejoin="round"#{dash_attr(dash)}/>)
    end

    def polyline(points, stroke: STROKE, width: 2.5, dash: nil)
      raw %(<polyline points="#{points.map { |x, y| "#{r x},#{r y}" }.join(' ')}" fill="none" stroke="#{stroke}" stroke-width="#{width}" stroke-linejoin="round" stroke-linecap="round"#{dash_attr(dash)}/>)
    end

    def rect(x, y, w, h, fill: FILL, stroke: STROKE, width: 2.5, radius: 0, dash: nil)
      raw %(<rect x="#{r x}" y="#{r y}" width="#{r w}" height="#{r h}" rx="#{radius}" fill="#{fill}" stroke="#{stroke}" stroke-width="#{width}"#{dash_attr(dash)}/>)
    end

    def circle(cx, cy, radius, fill: "none", stroke: STROKE, width: 2.5, dash: nil)
      raw %(<circle cx="#{r cx}" cy="#{r cy}" r="#{r radius}" fill="#{fill}" stroke="#{stroke}" stroke-width="#{width}"#{dash_attr(dash)}/>)
    end

    def dot(cx, cy, radius = 5, color: STROKE)
      raw %(<circle cx="#{r cx}" cy="#{r cy}" r="#{r radius}" fill="#{color}"/>)
    end

    def text(x, y, content, size: 17, color: INK, anchor: "middle", weight: "400", style: "normal", rotate: nil)
      turn = rotate ? %( transform="rotate(#{r rotate} #{r x} #{r y})") : ""
      raw %(<text x="#{r x}" y="#{r y}" font-family="#{FONT}" font-size="#{size}" font-weight="#{weight}" font-style="#{style}" fill="#{color}" text-anchor="#{anchor}"#{turn}>#{escape(content)}</text>)
    end

    # A circular arc, swept *clockwise* on screen from a1 to a2 (degrees,
    # measured maths-style: 0 east, 90 north). Used for angle marks and pie
    # slices. The sweep flag is 1 because SVG's y axis points down, so its
    # "positive" direction is clockwise on screen.
    def arc(cx, cy, radius, a1, a2, stroke: STROKE, width: 2.5, fill: "none")
      x1, y1 = polar(cx, cy, radius, a1)
      x2, y2 = polar(cx, cy, radius, a2)
      large = ((a1 - a2) % 360) > 180 ? 1 : 0
      d = "M #{r x1} #{r y1} A #{r radius} #{r radius} 0 #{large} 1 #{r x2} #{r y2}"
      raw %(<path d="#{d}" fill="#{fill}" stroke="#{stroke}" stroke-width="#{width}"/>)
    end

    def sector(cx, cy, radius, a1, a2, fill: FILL, stroke: STROKE, width: 2)
      x1, y1 = polar(cx, cy, radius, a1)
      x2, y2 = polar(cx, cy, radius, a2)
      large = ((a1 - a2) % 360) > 180 ? 1 : 0
      d = "M #{r cx} #{r cy} L #{r x1} #{r y1} A #{r radius} #{r radius} 0 #{large} 1 #{r x2} #{r y2} Z"
      raw %(<path d="#{d}" fill="#{fill}" stroke="#{stroke}" stroke-width="#{width}"/>)
    end

    def ellipse(cx, cy, rx, ry, fill: "none", stroke: STROKE, width: 2.5, dash: nil)
      raw %(<ellipse cx="#{r cx}" cy="#{r cy}" rx="#{r rx}" ry="#{r ry}" fill="#{fill}" stroke="#{stroke}" stroke-width="#{width}"#{dash_attr(dash)}/>)
    end

    # The square corner mark.
    def right_angle(vertex, along1, along2, size: 14)
      p1 = toward(vertex, along1, size)
      p2 = toward(vertex, along2, size)
      corner = [ p1[0] + p2[0] - vertex[0], p1[1] + p2[1] - vertex[1] ]
      polyline([ p1, corner, p2 ], stroke: STROKE, width: 2)
    end

    # An angle mark at `vertex` between the rays to `a` and `b`, with a label.
    def angle_mark(vertex, a, b, label: nil, radius: 30, color: STROKE, label_size: 16)
      a1 = angle_of(vertex, a)
      a2 = angle_of(vertex, b)
      # Draw the interior angle, not the reflex one.
      a1, a2 = a2, a1 if ((a1 - a2) % 360) > 180
      arc(vertex[0], vertex[1], radius, a1, a2, stroke: color, width: 2)
      return self unless label

      mid = a2 + (((a1 - a2) % 360) / 2.0)
      lx, ly = polar(vertex[0], vertex[1], radius + 17, mid)
      text(lx, ly + 5, label, size: label_size, color: color)
    end

    # Tick marks across a segment, the textbook way of saying "these are equal".
    def ticks(p1, p2, count: 1, size: 7)
      mx = (p1[0] + p2[0]) / 2.0
      my = (p1[1] + p2[1]) / 2.0
      dx = p2[0] - p1[0]
      dy = p2[1] - p1[1]
      len = Math.sqrt((dx * dx) + (dy * dy))
      ux = dx / len
      uy = dy / len
      (0...count).each do |i|
        offset = (i - ((count - 1) / 2.0)) * 6
        cx = mx + (ux * offset)
        cy = my + (uy * offset)
        line(cx - (uy * size), cy + (ux * size), cx + (uy * size), cy - (ux * size), width: 2)
      end
      self
    end

    def arrow(x1, y1, x2, y2, color: MUTED, width: 2)
      line(x1, y1, x2, y2, color: color, width: width)
      angle = Math.atan2(y2 - y1, x2 - x1)
      [ angle + 2.6, angle - 2.6 ].each do |a|
        line(x2, y2, x2 + (Math.cos(a) * 9), y2 + (Math.sin(a) * 9), color: color, width: width)
      end
      self
    end

    # A dimension line with its measurement, drawn outside the figure.
    def dimension(x1, y1, x2, y2, label, offset: 18, size: 16)
      dx = x2 - x1
      dy = y2 - y1
      len = Math.sqrt((dx * dx) + (dy * dy))
      nx = -dy / len * offset
      ny = dx / len * offset
      line(x1 + nx, y1 + ny, x2 + nx, y2 + ny, color: MUTED, width: 1.5)
      line(x1, y1, x1 + (nx * 1.25), y1 + (ny * 1.25), color: MUTED, width: 1)
      line(x2, y2, x2 + (nx * 1.25), y2 + (ny * 1.25), color: MUTED, width: 1)
      lx = ((x1 + x2) / 2.0) + (nx * 1.7)
      ly = ((y1 + y2) / 2.0) + (ny * 1.7) + 5
      text(lx, ly, label, size: size, color: MUTED)
    end

    def to_figure
      markup = +%(<svg xmlns="http://www.w3.org/2000/svg" width="#{@width}" height="#{@height}" viewBox="0 0 #{@width} #{@height}">)
      markup << %(<rect width="#{@width}" height="#{@height}" fill="#ffffff"/>)
      markup << @parts.join
      markup << "</svg>"
      Figure.new(markup: markup, width: @width, height: @height)
    end

    def polar(cx, cy, radius, degrees)
      radians = degrees * Math::PI / 180
      [ cx + (radius * Math.cos(radians)), cy - (radius * Math.sin(radians)) ]
    end

    def angle_of(from, to)
      (Math.atan2(from[1] - to[1], to[0] - from[0]) * 180 / Math::PI) % 360
    end

    def toward(from, to, distance)
      dx = to[0] - from[0]
      dy = to[1] - from[1]
      len = Math.sqrt((dx * dx) + (dy * dy))
      [ from[0] + (dx / len * distance), from[1] + (dy / len * distance) ]
    end

    private

    def dash_attr(dash) = dash ? %( stroke-dasharray="#{dash}") : ""

    def r(value) = format("%g", value.to_f.round(2))

    def escape(content)
      content.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
    end
  end

  module_function

  def canvas(width, height)
    c = Canvas.new(width, height)
    yield c
    c.to_figure
  end
end
