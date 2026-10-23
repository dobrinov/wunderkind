import { Controller } from "@hotwired/stimulus"

// „Обиколка и лице": a shape on a unit grid whose sides the reader drags. The
// perimeter is the blue outline, the area the green inside, and both are shown
// with the formula filled in with the numbers on the sliders — so "2 · (a + b)"
// is always about the rectangle on the screen, never an abstraction.
const SVG = "http://www.w3.org/2000/svg"
const UNIT = 24 // pixels per grid square
const ORIGIN = [24, 216] // the grid's bottom-left corner in the 360 × 240 viewBox
const COLS = 14
const ROWS = 8
const OFFSET = 2 // how far a parallelogram's top slides right, in squares

// The slider labels each shape uses, by copy key. The triangle's sides are
// „страни" here, not „катети": this page is for grades 3–6.
const LABELS = {
  rect: [ "side_a", "side_b" ],
  square: [ "side", null ],
  tri: [ "side_a", "side_b" ],
  par: [ "base", "height" ],
  trap: [ "big_base", "height" ]
}

// The first slider's range for each shape, so every shape at every setting
// fits the 14 × 8 grid with its outline: a square no taller than the grid,
// a parallelogram whose slanted top (a + 2) stops one square short of the
// edge, a trapezium wide enough to have a top base shorter than its bottom.
const A_RANGE = {
  rect: [ 1, 12 ],
  square: [ 1, 8 ],
  tri: [ 1, 12 ],
  par: [ 1, 11 ],
  trap: [ 2, 12 ]
}

export default class extends Controller {
  static targets = ["shape", "a", "aLabel", "aOut", "b", "bRow", "bLabel", "bOut", "figure", "p", "pFormula", "s", "sFormula"]
  static values = { copy: Object, kind: { type: String, default: "rect" } }

  connect() {
    this.render()
  }

  pick({ params: { shape } }) {
    this.kindValue = shape
    this.render()
  }

  size() {
    this.render()
  }

  render() {
    const kind = this.kindValue
    const copy = this.copyValue
    const [min, max] = A_RANGE[kind]
    this.aTarget.min = min
    this.aTarget.max = max
    this.aTarget.value = Math.min(max, Math.max(min, Number(this.aTarget.value)))
    const a = Number(this.aTarget.value)
    const b = kind === "square" ? a : Number(this.bTarget.value)
    const [aKey, bKey] = LABELS[kind]

    this.shapeTargets.forEach((button) => button.setAttribute("aria-pressed", button.dataset.explainerShapeBuilderShapeParam === kind))
    this.aLabelTarget.textContent = copy[aKey]
    this.aOutTarget.textContent = a
    this.bRowTarget.hidden = !bKey
    if (bKey) this.bLabelTarget.textContent = copy[bKey]
    this.bOutTarget.textContent = b

    const shape = this.measure(kind, a, b)
    this.pTarget.textContent = `${this.equation("P", shape.perimeter)} ${copy.unit}`
    this.sTarget.textContent = `${this.equation("S", shape.area)} ${copy.area_unit}`
    this.pFormulaTarget.textContent = shape.pFormula
    this.sFormulaTarget.textContent = shape.sFormula
    this.draw(shape, copy[kind])
  }

  // The corners on the grid (in squares), the two measures and their formulas.
  measure(kind, a, b) {
    const n = (v) => this.number(v).replace("≈ ", "")
    // A formula with a rounded side in it is an approximation, and says so.
    const sign = (...values) => (values.every((v) => this.exact(v)) ? "=" : "≈")
    if (kind === "rect" || kind === "square") {
      return {
        corners: [ [ 0, 0 ], [ a, 0 ], [ a, b ], [ 0, b ] ],
        perimeter: 2 * (a + b),
        area: a * b,
        pFormula: kind === "square" ? `P = 4 · ${a}` : `P = 2 · (${a} + ${b})`,
        sFormula: kind === "square" ? `S = ${a} · ${a}` : `S = ${a} · ${b}`
      }
    }
    if (kind === "tri") {
      const c = Math.hypot(a, b)
      return {
        corners: [ [ 0, 0 ], [ a, 0 ], [ 0, b ] ],
        perimeter: a + b + c,
        area: (a * b) / 2,
        pFormula: `P ${sign(c)} ${a} + ${b} + ${n(c)}`,
        sFormula: `S = ${a} · ${b} : 2`
      }
    }
    if (kind === "par") {
      const side = Math.hypot(OFFSET, b)
      return {
        corners: [ [ 0, 0 ], [ a, 0 ], [ a + OFFSET, b ], [ OFFSET, b ] ],
        perimeter: 2 * (a + side),
        area: a * b,
        height: OFFSET,
        pFormula: `P ${sign(side)} 2 · (${a} + ${n(side)})`,
        sFormula: `S = ${a} · ${b}`
      }
    }
    // An isosceles trapezium: the top base 4 squares shorter than the bottom
    // where it can be, and never less than 1 square or equal to the bottom —
    // a = 2 to 4 shrink the slant instead, so it never turns into a rectangle.
    const inset = a >= 5 ? 2 : (a - 1) / 2
    const top = a - 2 * inset
    const side = Math.hypot(inset, b)
    return {
      corners: [ [ 0, 0 ], [ a, 0 ], [ a - inset, b ], [ inset, b ] ],
      perimeter: a + top + 2 * side,
      area: ((a + top) * b) / 2,
      height: inset,
      pFormula: `P ${sign(side)} ${a} + ${n(top)} + 2 · ${n(side)}`,
      sFormula: `S = (${a} + ${n(top)}) · ${b} : 2`
    }
  }

  draw(shape, name) {
    const x = (u) => ORIGIN[0] + u * UNIT
    const y = (u) => ORIGIN[1] - u * UNIT
    const svg = this.node("svg", { viewBox: "0 0 360 240", class: "w-full max-w-[560px]", role: "img" })
    svg.setAttribute("aria-label", this.copyValue.figure
      .replace("%{shape}", name)
      .replace("%{p}", this.number(shape.perimeter))
      .replace("%{s}", this.number(shape.area)))

    for (let i = 0; i <= COLS; i++) svg.append(this.node("line", { x1: x(i), y1: y(0), x2: x(i), y2: y(ROWS), stroke: "#e5e7eb", "stroke-width": 1 }))
    for (let j = 0; j <= ROWS; j++) svg.append(this.node("line", { x1: x(0), y1: y(j), x2: x(COLS), y2: y(j), stroke: "#e5e7eb", "stroke-width": 1 }))

    svg.append(this.node("polygon", {
      points: shape.corners.map(([cx, cy]) => `${x(cx)},${y(cy)}`).join(" "),
      fill: "rgb(52 211 153 / .35)", stroke: "#4f46e5", "stroke-width": 4, "stroke-linejoin": "round"
    }))
    // The height of a slanted shape is not one of its sides: drawn dashed so
    // the reader sees which length the area uses.
    if (shape.height !== undefined) {
      const top = shape.corners[3][1]
      svg.append(this.node("line", { x1: x(shape.height), y1: y(0), x2: x(shape.height), y2: y(top), stroke: "#ea580c", "stroke-width": 2.5, "stroke-dasharray": "6 4" }))
    }
    this.figureTarget.replaceChildren(svg)
  }

  // A whole number as it is; an exact half with a decimal comma; anything else
  // rounded to one decimal and marked as rounded.
  number(value) {
    if (Number.isInteger(value)) return String(value)
    if (Math.abs(value * 2 - Math.round(value * 2)) < 1e-9) return String(value).replace(".", ",")
    return `≈ ${value.toFixed(1).replace(".", ",")}`
  }

  // Whether a value is shown exactly: a whole number or an exact half.
  exact(value) {
    return Math.abs(value * 2 - Math.round(value * 2)) < 1e-9
  }

  // "P = 20" for an exact value, "P ≈ 21,2" for a rounded one.
  equation(symbol, value) {
    const text = this.number(value)
    return text.startsWith("≈") ? `${symbol} ${text}` : `${symbol} = ${text}`
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
