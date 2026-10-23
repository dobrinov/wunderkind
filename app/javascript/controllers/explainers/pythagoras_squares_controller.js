import { Controller } from "@hotwired/stimulus"

// „Питагоровата теорема": legs a and b along the axes from the right angle C,
// and a square built outward on each side — the hypotenuse's from real
// coordinates, turned away from C. The figure is laid out so legs up to 8
// keep all three squares inside the 560 × 470 board.
const SVG = "http://www.w3.org/2000/svg"
const UNIT = 16
const C = [ 230, 270 ]

export default class extends Controller {
  static targets = ["a", "b", "aOut", "bOut", "figure", "sumA", "sumB", "sumC", "result"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const a = Number(this.aTarget.value)
    const b = Number(this.bTarget.value)
    const copy = this.copyValue
    const A = [ C[0] + a * UNIT, C[1] ]
    const B = [ C[0], C[1] - b * UNIT ]

    const squareA = [ C, A, [ A[0], A[1] + a * UNIT ], [ C[0], C[1] + a * UNIT ] ]
    const squareB = [ C, B, [ B[0] - b * UNIT, B[1] ], [ C[0] - b * UNIT, C[1] ] ]
    // Perpendicular to AB, pointing away from C: that side of the hypotenuse
    // is where its square goes.
    let normal = [ -(B[1] - A[1]), B[0] - A[0] ]
    const mid = [ (A[0] + B[0]) / 2, (A[1] + B[1]) / 2 ]
    if (normal[0] * (mid[0] - C[0]) + normal[1] * (mid[1] - C[1]) < 0) normal = [ -normal[0], -normal[1] ]
    const squareC = [ A, B, [ B[0] + normal[0], B[1] + normal[1] ], [ A[0] + normal[0], A[1] + normal[1] ] ]

    const a2 = a * a, b2 = b * b, c2 = a2 + b2
    const c = Math.sqrt(c2)
    // A rounded c swaps the copy's „=" for „≈" rather than reading „c = ≈ 1,41".
    const cText = Number.isInteger(c) ? `= ${c}` : `≈ ${c.toFixed(2).replace(".", ",")}`

    this.aOutTarget.textContent = a
    this.bOutTarget.textContent = b
    // Bare numbers: the a², b², c² names are on the squares themselves, and
    // „a² = 16 + b² = 9" in one row is a chain of equalities that is false.
    this.sumATarget.textContent = a2
    this.sumBTarget.textContent = b2
    this.sumCTarget.textContent = c2
    this.resultTarget.textContent = `→ ${copy.result.replace("= %{value}", cText)}`

    this.figureTarget.setAttribute("aria-label", copy.figure
      .replace("%{a}", a).replace("%{b}", b).replace("%{a2}", a2).replace("%{b2}", b2).replace("%{c2}", c2))
    this.figureTarget.replaceChildren(
      this.polygon(squareA, "rgb(127 127 247 / .35)", "#5048e5", 3),
      this.polygon(squareB, "rgb(251 191 36 / .4)", "#d97706", 3),
      this.polygon(squareC, "rgb(234 88 12 / .25)", "#c2410c", 3),
      this.polygon([ C, A, B ], "#ffffff", "#17162b", 3.5),
      this.node("path", { d: `M ${C[0] + 14} ${C[1]} V ${C[1] - 14} H ${C[0]}`, fill: "none", stroke: "#17162b", "stroke-width": 2 }),
      this.label(squareA, copy.area_a.replace("%{value}", a2), "#3730a3"),
      this.label(squareB, copy.area_b.replace("%{value}", b2), "#92400e"),
      this.label(squareC, copy.area_c.replace("%{value}", c2), "#9a3412")
    )
  }

  polygon(points, fill, stroke, width) {
    return this.node("polygon", {
      points: points.map(([x, y]) => `${x.toFixed(1)},${y.toFixed(1)}`).join(" "),
      fill, stroke, "stroke-width": width, "stroke-linejoin": "round"
    })
  }

  // The square's name in its middle — small squares get small type, so a
  // 1 × 1 square still holds its label.
  label(square, text, color) {
    const x = square.reduce((sum, [px]) => sum + px, 0) / 4
    const y = square.reduce((sum, [, py]) => sum + py, 0) / 4
    const side = Math.hypot(square[1][0] - square[0][0], square[1][1] - square[0][1])
    const size = Math.max(11, Math.min(20, side / 4))
    const element = this.node("text", {
      x, y: y + size / 3, "text-anchor": "middle", "font-family": "Nunito, sans-serif",
      "font-weight": 900, "font-size": size, fill: color
    })
    element.textContent = text
    return element
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
