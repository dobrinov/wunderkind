import { Controller } from "@hotwired/stimulus"

// „Какво е производна": the graph of f(x) = x², a point x₀ that slides along
// it and the tangent there — slope f′(x₀) = 2x₀, with its equation in
// numbers. A dashed secant runs through x₀ and x₀ + h, and its slope,
// (f(x₀ + h) − f(x₀)) : h, is worked beside the tangent's; shrinking h shows
// the one become the other. Only x² is offered: its secant's slope is exactly
// 2x₀ + h, so every number shown is exact and the gap between the two slopes
// is h itself. The two axes have the same scale, so a slope of 1 is drawn at
// 45° and a tangent looks as steep as its number says — which is why x₀
// stops at ±1,5 and h at 1: the board is x from −3 to 3 and y from −2 to 7.
const SVG = "http://www.w3.org/2000/svg"
// h runs over positions, not values: the small ones are the point.
const H_VALUES = [0.01, 0.1, 0.25, 0.5, 1]
// A narrow board — 320 units wide — so that its text is still 11 px and more
// on a phone, where the figure is about 290 px across.
const W = 320, H = 436
const OX = 160, OY = 328, UNIT = 44 // the origin and px per unit, the same on both axes
const X_MAX = 3, Y_MIN = -2, Y_MAX = 7 // x₀ + h is at most 2,5, where x² is 6,25

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
  static targets = ["x", "h", "xOut", "hOut", "figure", "tangent", "secant", "gap"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const x = Number(this.xTarget.value)
    const h = H_VALUES[Number(this.hTarget.value)]
    const xh = x + h
    const slope = 2 * x                     // f′(x₀)
    const secant = (xh * xh - x * x) / h    // = 2x₀ + h
    const fill = (text) => text.replaceAll("%{xh}", this.num(xh)).replaceAll("%{yh}", this.num(xh * xh)).replaceAll("%{xp}", this.paren(x))
      .replaceAll("%{x}", this.num(x)).replaceAll("%{y}", this.num(x * x)).replaceAll("%{h}", this.num(h))
      .replaceAll("%{slope}", this.num(slope)).replaceAll("%{secant}", this.num(secant))
      .replaceAll("%{equation}", this.equation(slope, -x * x))

    this.xOutTarget.textContent = this.num(x)
    this.hOutTarget.textContent = this.num(h)
    this.figureTarget.replaceChildren(this.graph(x, xh, slope, secant, fill(copy.figure)))
    this.tangentTarget.textContent = fill(copy.tangent)
    this.secantTarget.textContent = fill(copy.secant)
    this.gapTarget.textContent = fill(copy.gap)
  }

  // A number the way the page writes it: the locale's decimal sign and a real
  // minus. Four places hold everything exactly — x₀ + h has at most two, its
  // square at most four.
  num(value) {
    const rounded = Math.round(value * 10000) / 10000
    return (rounded < 0 ? "−" : "") + String(Math.abs(rounded)).replace(".", this.copyValue.point)
  }

  // A negative factor gets brackets: 2 · (−1,5).
  paren(value) {
    return value < 0 ? `(${this.num(value)})` : this.num(value)
  }

  // y = 2x − 1, y = −x − 0,25, y = 0: no "1x", no "+ −1", no "+ 0".
  equation(k, n) {
    if (k === 0) return `y = ${this.num(n)}`
    const kx = (k < 0 ? "−" : "") + (Math.abs(k) === 1 ? "" : this.num(Math.abs(k))) + "x"
    return n === 0 ? `y = ${kx}` : `y = ${kx} ${n < 0 ? "−" : "+"} ${this.num(Math.abs(n))}`
  }

  graph(x, xh, slope, secant, label) {
    const copy = this.copyValue
    const svg = this.node("svg", { viewBox: `0 0 ${W} ${H}`, class: "w-full max-w-[340px]", role: "img" })
    svg.setAttribute("aria-label", label)
    const busy = []
    this.board(svg, busy)

    // The parabola up to where it leaves the top of the board, at x = ±√7.
    const edge = Math.sqrt(Y_MAX)
    let d = ""
    for (let i = 0; i <= 160; i++) {
      const at = -edge + (2 * edge * i) / 160
      d += `${i ? " L" : "M"} ${px(at).toFixed(1)} ${py(at * at).toFixed(1)}`
      busy.push(around(px(at), py(at * at), 3))
    }
    svg.append(this.node("path", { d, fill: "none", stroke: "#a5aaff", "stroke-width": 4, "stroke-linecap": "round", "stroke-linejoin": "round" }))

    // Both lines pass through (x₀; x₀²), which is on the board, so the piece
    // of each inside the board is never empty.
    this.line(svg, busy, x, x * x, secant, { stroke: "#50506b", "stroke-width": 2.5, "stroke-dasharray": "7 5" })
    this.line(svg, busy, x, x * x, slope, { stroke: "#312e81", "stroke-width": 3, "stroke-linecap": "round" })

    svg.append(this.node("circle", { cx: px(xh), cy: py(xh * xh), r: 5.5, fill: "#ffffff", stroke: "#50506b", "stroke-width": 2.5 }))
    svg.append(this.node("circle", { cx: px(x), cy: py(x * x), r: 6.5, fill: "#312e81", stroke: "#f5f5fa", "stroke-width": 2 }))
    busy.push(around(px(xh), py(xh * xh), 7), around(px(x), py(x * x), 8))

    // The curve's name inside one arm or the other, whichever the lines leave free.
    this.place(svg, busy, copy.curve_label, 14, [{ x: px(-2.35), y: py(6.55) }, { x: px(2.35), y: py(6.55), anchor: "end" }], { fill: "#5048e5" })
    this.ticks(svg, busy, [-3, -2, -1, 1, 2, 3], [2, 4, 6])
    return svg
  }

  // The line through (x0; y0) with this slope, cut where it leaves the board.
  line(svg, busy, x0, y0, slope, attributes) {
    let from = -X_MAX, to = X_MAX
    if (slope !== 0) {
      const atTop = x0 + (Y_MAX - y0) / slope, atBottom = x0 + (Y_MIN - y0) / slope
      from = Math.max(from, Math.min(atTop, atBottom))
      to = Math.min(to, Math.max(atTop, atBottom))
    }
    const at = (x) => y0 + slope * (x - x0)
    svg.append(this.node("line", { x1: px(from).toFixed(1), y1: py(at(from)).toFixed(1), x2: px(to).toFixed(1), y2: py(at(to)).toFixed(1), ...attributes }))
    busy.push(...along(px(from), py(at(from)), px(to), py(at(to)), 3))
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
    svg.append(this.text(copy.x_axis, { x: px(X_MAX) + 9, y: OY + 5, "font-size": 14, "font-weight": 900, fill: "#50506b" }))
    svg.append(this.text(copy.y_axis, { x: OX, y: py(Y_MAX) - 6, "text-anchor": "middle", "font-size": 14, "font-weight": 900, fill: "#50506b" }))
    busy.push(textBox(copy.x_axis, 14, px(X_MAX) + 9, OY + 5), textBox(copy.y_axis, 14, OX, py(Y_MAX) - 6, "middle"))
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
