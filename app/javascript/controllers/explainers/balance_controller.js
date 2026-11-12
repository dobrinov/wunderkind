import { Controller } from "@hotwired/stimulus"

// „Линейни уравнения": ax + b = c on a pair of scales. The left pan holds a
// boxes, each hiding x units, and b loose units; the right pan holds c. The
// scales stay level through both moves — b off each pan, then the rest shared
// among the boxes — which is the whole of what solving the equation means.
const SVG = "http://www.w3.org/2000/svg"
const WIDTH = 520, PAN_Y = 196, LEFT = 130, RIGHT = 390
const BOX = 40, UNIT = 7, PER_ROW = 6

const random = (from, to) => from + Math.floor(Math.random() * (to - from + 1))

export default class extends Controller {
  static targets = ["equation", "figure", "note", "step"]
  static values = { copy: Object }

  connect() {
    // The article's own example first: 3x + 4 = 19.
    this.set(3, 4, 5)
  }

  // A new equation with a whole answer, never the one on screen.
  fresh() {
    let a, b, x
    do { [a, b, x] = [random(2, 4), random(1, 6), random(1, 6)] } while (a === this.a && b === this.b && x === this.x)
    this.set(a, b, x)
  }

  next() {
    this.step = (this.step + 1) % 3
    this.render()
  }

  set(a, b, x) {
    Object.assign(this, { a, b, x, step: 0 })
    this.render()
  }

  render() {
    const { a, b, x, step } = this
    const copy = this.copyValue
    const c = a * x + b
    const rest = c - b
    const fill = (text) => text.replaceAll("%{a}", a).replaceAll("%{b}", b).replaceAll("%{c}", c)
      .replaceAll("%{rest}", rest).replaceAll("%{x}", x)

    const equation = [`${a}x + ${b} = ${c}`, `${a}x = ${rest}`, `x = ${x}`][step]
    this.equationTarget.textContent = equation
    this.noteTarget.textContent = fill([copy.start, copy.took, copy.shared][step])
    this.stepTarget.textContent = fill([copy.take, copy.share, copy.again][step])

    // What is on each pan now: boxes and loose units on the left, units on
    // the right. Solved, one box faces its x units.
    const left = step === 2 ? { boxes: 1, units: 0 } : { boxes: a, units: step === 0 ? b : 0 }
    const right = [c, rest, x][step]
    this.figureTarget.replaceChildren(this.scales(left, right, fill(copy.figure).replace("%{equation}", equation)))
  }

  scales(left, right, label) {
    const svg = this.node("svg", { viewBox: `0 0 ${WIDTH} 250`, class: "w-full max-w-[560px]", role: "img" })
    svg.setAttribute("aria-label", label)

    // The stand and the two pans. Always level: that is the point.
    svg.append(this.node("path", { d: `M ${WIDTH / 2 - 22} 240 L ${WIDTH / 2} 204 L ${WIDTH / 2 + 22} 240 Z`, fill: "#c5c5d6" }))
    svg.append(this.node("line", { x1: LEFT - 100, y1: PAN_Y + 6, x2: RIGHT + 100, y2: PAN_Y + 6, stroke: "#9a9ab0", "stroke-width": 5, "stroke-linecap": "round" }))

    // Left pan: the boxes in a row, the loose units in a row above them.
    const boxesWidth = left.boxes * BOX + (left.boxes - 1) * 6
    for (let i = 0; i < left.boxes; i++) {
      const x = LEFT - boxesWidth / 2 + i * (BOX + 6)
      svg.append(this.node("rect", { x, y: PAN_Y - BOX, width: BOX, height: BOX, rx: 8, fill: "#5048e5" }))
      const text = this.node("text", { x: x + BOX / 2, y: PAN_Y - BOX / 2 + 7, "text-anchor": "middle", "font-size": 20, "font-weight": 900, fill: "#ffffff" })
      text.textContent = "x"
      svg.append(text)
    }
    this.units(svg, LEFT, PAN_Y - BOX - 8, left.units)
    this.units(svg, RIGHT, PAN_Y, right)
    return svg
  }

  // `count` units stacked up from `bottom`, centred on `centre`, six to a row.
  units(svg, centre, bottom, count) {
    for (let i = 0; i < count; i++) {
      const row = Math.floor(i / PER_ROW)
      const inRow = Math.min(PER_ROW, count - row * PER_ROW)
      const x = centre - ((inRow - 1) * (UNIT * 2 + 4)) / 2 + (i % PER_ROW) * (UNIT * 2 + 4)
      svg.append(this.node("circle", { cx: x, cy: bottom - UNIT - row * (UNIT * 2 + 4), r: UNIT, fill: "#a5aaff", stroke: "#5048e5", "stroke-width": 2 }))
    }
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
