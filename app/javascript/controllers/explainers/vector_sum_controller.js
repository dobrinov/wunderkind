import { Controller } from "@hotwired/stimulus"

// „Какво е вектор?": two vectors set by steps right and up, the first one
// multiplied by a number, and their sum drawn tip to tail. The dashed
// parallelogram is the other order — orange first — ending at the same point.
//
// Steps run −3..5 and the multiplier −1..2, so every point the figure draws
// stays within −9..15 on both axes, and the grid is drawn exactly that big.
const SVG = "http://www.w3.org/2000/svg"
const ORIGIN = [180, 290]
const UNIT = 18
const RANGE = [-9, 15]
const STEPS = [-3, 5]

export default class extends Controller {
  static targets = ["ux", "uy", "vx", "vy", "multiplier", "multiplierOut", "figure", "blue", "orange", "sum"]
  static values = { copy: Object }

  connect() {
    this.state = { ux: 4, uy: 2, vx: 2, vy: 5, k: 1 }
    this.render()
  }

  step({ params: { key, delta } }) {
    this.state[key] = Math.max(STEPS[0], Math.min(STEPS[1], this.state[key] + Number(delta)))
    this.render()
  }

  scale() {
    this.state.k = Number(this.multiplierTarget.value)
    this.render()
  }

  render() {
    const { ux, uy, vx, vy, k } = this.state
    const blue = [k * ux, k * uy]
    const sum = [blue[0] + vx, blue[1] + vy]
    const copy = this.copyValue
    const pair = ([x, y]) => `${this.number(x)}; ${this.number(y)}`

    for (const key of ["ux", "uy", "vx", "vy"]) this[`${key}Target`].textContent = this.number(this.state[key])
    this.multiplierOutTarget.textContent = this.number(k)
    this.blueTarget.textContent = copy.blue.replace("%{v}", pair(blue))
    this.orangeTarget.textContent = copy.orange.replace("%{v}", pair([vx, vy]))
    const length = Math.hypot(...sum)
    const lengthText = Math.abs(length - Math.round(length)) < 1e-9 ? this.number(Math.round(length)) : `≈ ${this.number(length)}`
    this.sumTarget.textContent = copy.sum.replace("%{v}", pair(sum)).replace("%{length}", lengthText)

    const svg = this.node("svg", { viewBox: "0 0 480 470", class: "w-full max-w-[540px]", role: "img" })
    svg.setAttribute("aria-label", copy.figure.replace("%{u}", pair(blue)).replace("%{v}", pair([vx, vy])).replace("%{s}", pair(sum)))
    this.grid(svg)
    svg.append(this.node("polygon", {
      points: [[0, 0], blue, sum, [vx, vy]].map((p) => this.at(p).join(",")).join(" "),
      fill: "rgb(52 211 153 / .12)", stroke: "#9a9ab0", "stroke-width": 1.5, "stroke-dasharray": "6 5"
    }))
    if (blue[0] || blue[1]) svg.append(...this.arrow([0, 0], blue, "#5048e5", 5))
    if (vx || vy) svg.append(...this.arrow(blue, sum, "#ea580c", 5))
    if (sum[0] || sum[1]) svg.append(...this.arrow([0, 0], sum, "#059669", 6))
    this.figureTarget.replaceChildren(svg)
  }

  grid(svg) {
    const [lo, hi] = RANGE
    for (let i = lo; i <= hi; i++) {
      const axis = i === 0
      const stroke = axis ? "#9a9ab0" : "#ececf4"
      const width = axis ? 2 : 1
      svg.append(this.node("line", { x1: this.at([i, lo])[0], y1: this.at([i, lo])[1], x2: this.at([i, hi])[0], y2: this.at([i, hi])[1], stroke, "stroke-width": width }))
      svg.append(this.node("line", { x1: this.at([lo, i])[0], y1: this.at([lo, i])[1], x2: this.at([hi, i])[0], y2: this.at([hi, i])[1], stroke, "stroke-width": width }))
    }
  }

  arrow(from, to, color, width) {
    const [x1, y1] = this.at(from)
    const [x2, y2] = this.at(to)
    const length = Math.hypot(x2 - x1, y2 - y1) || 1
    const [dx, dy] = [(x2 - x1) / length, (y2 - y1) / length]
    const [hx, hy] = [x2 - dx * 14, y2 - dy * 14]
    const head = [[x2, y2], [hx - dy * 7, hy + dx * 7], [hx + dy * 7, hy - dx * 7]]
    return [
      this.node("line", { x1, y1, x2: hx + dx * 4, y2: hy + dy * 4, stroke: color, "stroke-width": width, "stroke-linecap": "round" }),
      this.node("polygon", { points: head.map((p) => p.map((v) => v.toFixed(1)).join(",")).join(" "), fill: color })
    ]
  }

  at([x, y]) {
    return [ORIGIN[0] + x * UNIT, ORIGIN[1] - y * UNIT]
  }

  // A number as the article writes it: decimal comma and a real minus sign.
  number(value) {
    const rounded = Math.round(value * 100) / 100
    return String(rounded).replace(".", ",").replace("-", "−")
  }

  node(tag, attributes = {}) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
