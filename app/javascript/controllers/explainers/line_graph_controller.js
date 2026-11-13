import { Controller } from "@hotwired/stimulus"

// „Линейна функция": y = kx + n drawn on a square grid as k and n move. The
// point (0; n) is marked, and a step triangle starts from it — one unit to
// the right, k up or down — because the ъглов коефициент is exactly that
// step. The grid's units are equal on both axes so the slope looks like what
// it is, and the board is tall enough (±8) to hold the step's far corner
// (0 + 1; n + k) at every position of the sliders. Labels are placed by
// trying places until one is clear, and an axis number that something else
// needs the room of is left out.
const SVG = "http://www.w3.org/2000/svg"
// A narrow board — 320 units wide — so that its text is still 11 px and more
// on a phone, where the figure is about 290 px across.
const W = 320, H = 488
const OX = 160, OY = 244, UNIT = 28 // the origin and px per unit
const X_MAX = 5, Y_MAX = 8, Y_MIN = -8

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
  static targets = ["k", "n", "kOut", "nOut", "equation", "figure", "step", "verdict", "cross"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const k = Number(this.kTarget.value)
    const n = Number(this.nTarget.value)
    const equation = this.equation(k, n)

    this.kOutTarget.textContent = this.num(k)
    this.nOutTarget.textContent = this.num(n)
    this.equationTarget.textContent = equation
    this.figureTarget.replaceChildren(this.graph(k, n, copy.figure.replaceAll("%{equation}", equation).replaceAll("%{n}", this.num(n))))

    this.stepTarget.textContent = (k > 0 ? copy.step_up : k < 0 ? copy.step_down : copy.step_flat).replaceAll("%{k}", this.num(Math.abs(k)))
    this.verdictTarget.textContent = (k > 0 ? copy.rising : k < 0 ? copy.falling : copy.constant).replaceAll("%{n}", this.num(n))
    this.crossTarget.textContent = k !== 0 ? copy.cross.replaceAll("%{x}", this.rel(-n / k)) : n === 0 ? copy.cross_all : copy.cross_none
  }

  // A number the way the page writes it: the locale's decimal sign and a real
  // minus, rounded to two places (and never "−0").
  num(value) {
    const rounded = Math.round(value * 100) / 100
    return (rounded < 0 ? "−" : "") + String(Math.abs(rounded)).replace(".", this.copyValue.point)
  }

  // "= −0,5" when exact, "≈ 3,33" when it had to be rounded.
  rel(value) {
    return (Math.abs(Math.round(value * 100) / 100 - value) > 1e-9 ? "≈\u00a0" : "=\u00a0") + this.num(value)
  }

  // y = 2x + 1, y = −x − 3, y = 0,5x, y = 4: no "1x", no "+ −3", no "+ 0".
  equation(k, n) {
    if (k === 0) return `y = ${this.num(n)}`
    const kx = (k < 0 ? "−" : "") + (Math.abs(k) === 1 ? "" : this.num(Math.abs(k))) + "x"
    return n === 0 ? `y = ${kx}` : `y = ${kx} ${n < 0 ? "−" : "+"} ${this.num(Math.abs(n))}`
  }

  graph(k, n, label) {
    const copy = this.copyValue
    const svg = this.node("svg", { viewBox: `0 0 ${W} ${H}`, class: "w-full max-w-[340px]", role: "img" })
    svg.setAttribute("aria-label", label)
    const busy = []
    this.board(svg, busy)

    // The line, cut where it leaves the board: (0; n) is always on it, so the
    // piece inside is never empty.
    let from = -X_MAX, to = X_MAX
    if (k !== 0) {
      const atTop = (Y_MAX - n) / k, atBottom = (Y_MIN - n) / k
      from = Math.max(from, Math.min(atTop, atBottom))
      to = Math.min(to, Math.max(atTop, atBottom))
    }
    svg.append(this.node("line", { x1: px(from), y1: py(k * from + n), x2: px(to), y2: py(k * to + n), stroke: "#5048e5", "stroke-width": 4, "stroke-linecap": "round" }))
    busy.push(...along(px(from), py(k * from + n), px(to), py(k * to + n), 3))

    // Where it meets the x-axis, when that is on the board and is not (0; n) itself.
    if (k !== 0 && n !== 0 && Math.abs(n / k) <= X_MAX) {
      svg.append(this.node("circle", { cx: px(-n / k), cy: OY, r: 6, fill: "#ffffff", stroke: "#5048e5", "stroke-width": 3 }))
      busy.push(around(px(-n / k), OY, 8))
    }

    // The step: one to the right, k up or down.
    svg.append(this.node("line", { x1: px(0), y1: py(n), x2: px(1), y2: py(n), stroke: "#312e81", "stroke-width": 2.5, "stroke-linecap": "round" }))
    busy.push(...along(px(0), py(n), px(1), py(n), 2))
    if (k !== 0) {
      svg.append(this.node("line", { x1: px(1), y1: py(n), x2: px(1), y2: py(n + k), stroke: "#312e81", "stroke-width": 2.5, "stroke-linecap": "round" }))
      busy.push(...along(px(1), py(n), px(1), py(n + k), 2))
    }
    svg.append(this.node("circle", { cx: px(0), cy: py(n), r: 6, fill: "#312e81", stroke: "#f5f5fa", "stroke-width": 2 }))
    busy.push(around(px(0), py(n), 7))

    // The labels, each on the side its leg has room on: the first place that
    // is clear of the line, the step and the labels before it.
    const ink = { fill: "#312e81" }
    this.place(svg, busy, copy.run_label, 14, [
      { x: px(0.5), y: py(n) + 17, anchor: "middle" }, { x: px(0.5), y: py(n) - 8, anchor: "middle" }
    ], ink)
    const rise = copy.rise_label.replaceAll("%{k}", this.num(k))
    this.place(svg, busy, rise, 14, [
      { x: px(1) + 8, y: py(n + k / 2) + 5 }, { x: px(1) + 8, y: py(n) + 18 }, { x: px(1) + 8, y: py(n) - 10 },
      { x: px(1) + 8, y: py(n + k) + 18 }, { x: px(1) + 8, y: py(n + k) - 10 }, { x: px(2), y: py(n) + 18 }, { x: px(2), y: py(n) - 10 }
    ], ink)
    const intercept = copy.intercept_label.replaceAll("%{n}", this.num(n))
    this.place(svg, busy, intercept, 14, [
      { x: px(0) - 10, y: py(n) - 11, anchor: "end" }, { x: px(0) - 10, y: py(n) + 22, anchor: "end" },
      { x: px(0) - 12, y: py(n) + 5, anchor: "end" }, { x: px(0) - 24, y: py(n) - 11, anchor: "end" }, { x: px(0) - 24, y: py(n) + 22, anchor: "end" }
    ], ink)

    this.ticks(svg, busy, [-4, -2, 2, 4], [-8, -6, -4, -2, 2, 4, 6, 8])
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
