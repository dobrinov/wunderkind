import { Controller } from "@hotwired/stimulus"

// „Парабола и квадратна функция": y = a(x − p)² + q on a square grid. The
// sliders are the vertex itself — p and q slide the curve, a narrows, widens
// or flips it — so the vertex (p; q) and the axis x = p are read off the
// formula before any calculation. Under the picture the same function is
// expanded to ax² + bx + c and x₀ = −b : (2a) is worked with those numbers,
// landing on p: the formula and the picture say the same thing.
// (The roots and the discriminant are the „Квадратни уравнения" article's.)
const SVG = "http://www.w3.org/2000/svg"
// a = 0 is not a parabola, so the slider runs over positions and steps from
// −0,5 straight to 0,5.
const A_VALUES = [-2, -1.5, -1, -0.5, 0.5, 1, 1.5, 2]
// A narrow board — 320 units wide — so that its text is still 11 px and more
// on a phone, where the figure is about 290 px across.
const W = 320, H = 424
const OX = 160, OY = 212, UNIT = 24 // the origin and px per unit
const X_MAX = 6, Y_MAX = 8, Y_MIN = -8

const px = (x) => OX + x * UNIT
const py = (y) => OY - y * UNIT

// Where things are, so that nothing is written over anything else. A label's
// box is estimated from its length (bold digits and letters run about 0,62 em
// wide); a line or a curve is a string of small boxes along it.
const CHAR = 0.62
function textBox(content, size, x, y, anchor = "start") {
  const width = [...content].length * size * CHAR
  const left = anchor === "middle" ? x - width / 2 : anchor === "end" ? x - width : x
  return { left, right: left + width, top: y - size * 0.8, bottom: y + size * 0.22 }
}
const around = (x, y, r) => ({ left: x - r, right: x + r, top: y - r, bottom: y + r })
const hits = (a, b) => a.left < b.right + 2 && b.left < a.right + 2 && a.top < b.bottom + 2 && b.top < a.bottom + 2
function along(x1, y1, x2, y2, r) {
  const steps = Math.max(1, Math.ceil(Math.hypot(x2 - x1, y2 - y1) / 4))
  return Array.from({ length: steps + 1 }, (_, i) => around(x1 + ((x2 - x1) * i) / steps, y1 + ((y2 - y1) * i) / steps, r))
}

export default class extends Controller {
  static targets = ["a", "p", "q", "aOut", "pOut", "qOut", "equation", "figure", "vertex", "expanded", "check"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const a = A_VALUES[Number(this.aTarget.value)]
    const p = Number(this.pTarget.value)
    const q = Number(this.qTarget.value)
    // Expanded: a(x − p)² + q = ax² − 2ap·x + (ap² + q). a is a multiple of
    // 0,5 and p, q are whole, so b and c are exact.
    const b = -2 * a * p
    const c = a * p * p + q
    const equation = this.vertexForm(a, p, q)
    const fill = (text) => text.replaceAll("%{equation}", equation).replaceAll("%{p}", this.num(p)).replaceAll("%{q}", this.num(q))

    this.aOutTarget.textContent = this.num(a)
    this.pOutTarget.textContent = this.num(p)
    this.qOutTarget.textContent = this.num(q)
    this.equationTarget.textContent = equation
    this.figureTarget.replaceChildren(this.graph(a, p, q, fill(a > 0 ? copy.figure_min : copy.figure_max)))

    this.vertexTarget.textContent = fill(a > 0 ? copy.vertex_min : copy.vertex_max)
    this.expandedTarget.textContent = copy.expanded.replaceAll("%{poly}", `y = ${this.term(a, "x²", true)}${this.term(b, "x", false)}${this.term(c, "", false)}`)
    this.checkTarget.textContent = copy.check.replaceAll("%{minus_b}", this.num(-b)).replaceAll("%{two_a}", this.paren(2 * a)).replaceAll("%{p}", this.num(p))
  }

  // A number the way the page writes it: the locale's decimal sign and a real
  // minus, rounded to two places (and never "−0").
  num(value) {
    const rounded = Math.round(value * 100) / 100
    return (rounded < 0 ? "−" : "") + String(Math.abs(rounded)).replace(".", this.copyValue.point)
  }

  // A negative divisor gets brackets.
  paren(value) {
    return value < 0 ? `(${this.num(value)})` : this.num(value)
  }

  // y = 0,5(x − 2)² − 3, y = −(x + 1)², y = 2x² + 4: no "1(", no "x − 0", no "+ 0".
  vertexForm(a, p, q) {
    const lead = a === 1 ? "" : a === -1 ? "−" : this.num(a)
    const square = p === 0 ? "x²" : `(x ${p > 0 ? "−" : "+"} ${this.num(Math.abs(p))})²`
    const tail = q === 0 ? "" : ` ${q < 0 ? "−" : "+"} ${this.num(Math.abs(q))}`
    return `y = ${lead}${square}${tail}`
  }

  // One term of the expanded form: no "1x", no "+ −3", nothing for a zero.
  term(coefficient, variable, first) {
    if (coefficient === 0) return ""
    const magnitude = Math.abs(coefficient)
    const shown = variable && magnitude === 1 ? "" : this.num(magnitude)
    const sign = coefficient < 0 ? (first ? "−" : " − ") : (first ? "" : " + ")
    return sign + shown + variable
  }

  graph(a, p, q, label) {
    const copy = this.copyValue
    const svg = this.node("svg", { viewBox: `0 0 ${W} ${H}`, class: "w-full max-w-[360px]", role: "img" })
    svg.setAttribute("aria-label", label)
    const busy = []
    this.board(svg, busy)

    // The axis of symmetry, the whole height of the board.
    svg.append(this.node("line", { x1: px(p), y1: py(Y_MAX), x2: px(p), y2: py(Y_MIN), stroke: "#312e81", "stroke-width": 2, "stroke-dasharray": "6 5" }))
    busy.push(...along(px(p), py(Y_MAX), px(p), py(Y_MIN), 2))

    // The curve between the two points where it leaves the board: the arms
    // reach the top edge (a > 0) or the bottom one (a < 0) at p ± reach.
    const reach = Math.sqrt(((a > 0 ? Y_MAX : Y_MIN) - q) / a)
    const from = Math.max(-X_MAX, p - reach), to = Math.min(X_MAX, p + reach)
    let d = ""
    for (let i = 0; i <= 160; i++) {
      const x = from + ((to - from) * i) / 160
      const y = a * (x - p) ** 2 + q
      d += `${i ? " L" : "M"} ${px(x).toFixed(1)} ${py(y).toFixed(1)}`
      busy.push(around(px(x), py(y), 3))
    }
    svg.append(this.node("path", { d, fill: "none", stroke: "#5048e5", "stroke-width": 4, "stroke-linecap": "round", "stroke-linejoin": "round" }))

    svg.append(this.node("circle", { cx: px(p), cy: py(q), r: 7, fill: "#312e81", stroke: "#f5f5fa", "stroke-width": 2 }))
    busy.push(around(px(p), py(q), 8))

    // Both labels go on the side the parabola does not open to, where nothing
    // else is drawn, and beside the dashed axis, not on it: the vertex's next
    // to the vertex, the axis's at the edge of the board.
    const fill = (text) => text.replaceAll("%{p}", this.num(p)).replaceAll("%{q}", this.num(q))
    const ink = { fill: "#312e81" }
    const beside = (y, first, second) => [{ x: px(p) + first * 9, y, anchor: first > 0 ? "start" : "end" }, { x: px(p) + second * 9, y, anchor: second > 0 ? "start" : "end" }]
    this.place(svg, busy, fill(copy.vertex_label), 14, beside(py(q) + (a > 0 ? 23 : -14), 1, -1), ink)
    this.place(svg, busy, fill(copy.axis_label), 14, beside(a > 0 ? py(Y_MIN) - 7 : py(Y_MAX) + 16, -1, 1), ink)

    this.ticks(svg, busy, [-6, -4, -2, 2, 4, 6], [-8, -6, -4, -2, 2, 4, 6, 8])
    return svg
  }

  // Writes a label at the first of its candidate places that is on the board
  // and clear of everything drawn so far, and marks the place taken. A label
  // with nowhere to go is left out rather than written over something.
  place(svg, busy, content, size, candidates, attributes) {
    for (const { x, y, anchor = "start" } of candidates) {
      const box = textBox(content, size, x, y, anchor)
      if (box.left < 2 || box.right > W - 2 || box.top < 2 || box.bottom > H - 2 || busy.some((other) => hits(box, other))) continue
      busy.push(box)
      svg.append(this.text(content, { x, y, "text-anchor": anchor, "font-size": size, "font-weight": 900, stroke: "#f5f5fa", "stroke-width": 5, "stroke-linejoin": "round", "paint-order": "stroke", ...attributes }))
      return true
    }
    return false
  }

  // The grid, the axes and their letters. The letters sit in the margin, off
  // the board, where no line can reach them.
  board(svg, busy) {
    const copy = this.copyValue
    for (let x = -X_MAX; x <= X_MAX; x++) {
      svg.append(this.node("line", { x1: px(x), y1: py(Y_MAX), x2: px(x), y2: py(Y_MIN), stroke: x === 0 ? "#9a9ab0" : "#e2e2ee", "stroke-width": x === 0 ? 2 : 1 }))
    }
    for (let y = Y_MIN; y <= Y_MAX; y++) {
      svg.append(this.node("line", { x1: px(-X_MAX), y1: py(y), x2: px(X_MAX), y2: py(y), stroke: y === 0 ? "#9a9ab0" : "#e2e2ee", "stroke-width": y === 0 ? 2 : 1 }))
    }
    svg.append(this.text(copy.x_axis, { x: px(X_MAX) + 5, y: OY + 5, "font-size": 14, "font-weight": 900, fill: "#50506b" }))
    svg.append(this.text(copy.y_axis, { x: OX, y: py(Y_MAX) - 6, "text-anchor": "middle", "font-size": 14, "font-weight": 900, fill: "#50506b" }))
    busy.push(textBox(copy.x_axis, 14, px(X_MAX) + 5, OY + 5), textBox(copy.y_axis, 14, OX, py(Y_MAX) - 6, "middle"))
  }

  // The numbers on the axes, each only where nothing else is: a number under
  // a label or a line is left out, the rest still give the scale.
  ticks(svg, busy, xs, ys) {
    const minus = (tick) => String(tick).replace("-", "−")
    for (const tick of xs) this.place(svg, busy.slice(), minus(tick), 13, [{ x: px(tick), y: OY + 16, anchor: "middle" }], { "font-weight": 700, fill: "#666680" })
    for (const tick of ys) this.place(svg, busy.slice(), minus(tick), 13, [{ x: OX - 8, y: py(tick) + 5, anchor: "end" }], { "font-weight": 700, fill: "#666680" })
  }

  text(content, attributes) {
    const element = this.node("text", attributes)
    element.textContent = content
    return element
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
