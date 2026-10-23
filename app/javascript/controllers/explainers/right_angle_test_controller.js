import { Controller } from "@hotwired/stimulus"

// The converse of Pythagoras: sides 3 and 4 around an angle γ at C, so the
// third side's square is 3² + 4² − 2·3·4·cos γ = 25 − 24·cos γ, which is 25
// only at 90°. Drawn to scale (42 px per unit) inside a 520 × 260 board for
// every angle from 40° to 140°.
const SVG = "http://www.w3.org/2000/svg"
const SCALE = 42
const C = [ 200, 220 ]

export default class extends Controller {
  static targets = ["angle", "angleOut", "figure", "compare", "third", "note"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const degrees = Number(this.angleTarget.value)
    const radians = (degrees * Math.PI) / 180
    const copy = this.copyValue
    const A = [ C[0] + 4 * SCALE, C[1] ]
    const B = [ C[0] + 3 * SCALE * Math.cos(radians), C[1] - 3 * SCALE * Math.sin(radians) ]
    const c2 = degrees === 90 ? 25 : 25 - 24 * Math.cos(radians)
    const rounded = Math.round(c2 * 100) / 100
    const c2Text = Number.isInteger(rounded) ? `= ${rounded}` : `≈ ${rounded.toFixed(2).replace(".", ",")}`
    const kind = degrees === 90 ? "equal" : degrees < 90 ? "acute" : "obtuse"

    this.angleOutTarget.textContent = `${degrees}°`
    this.compareTarget.textContent = kind === "equal" ? "=" : kind === "acute" ? ">" : "<"
    this.compareTarget.className = [
      "rounded-full px-3.5 py-1",
      kind === "equal" ? "bg-green-100 text-green-800" : "bg-reward-100 text-reward-800"
    ].join(" ")
    this.thirdTarget.textContent = copy.third.replace("= %{value}", c2Text)
    this.noteTarget.textContent = copy[kind]

    this.figureTarget.setAttribute("aria-label", copy.figure.replace("%{angle}", degrees))
    this.figureTarget.replaceChildren(
      this.node("polygon", {
        points: [ C, A, B ].map(([x, y]) => `${x.toFixed(1)},${y.toFixed(1)}`).join(" "),
        fill: kind === "equal" ? "rgb(52 211 153 / .2)" : "rgb(127 127 247 / .15)",
        stroke: "#17162b", "stroke-width": 3.5, "stroke-linejoin": "round"
      }),
      this.text("C", C[0] - 14, C[1] + 22),
      this.text("A", A[0] + 14, A[1] + 22),
      this.text("B", B[0], B[1] - 12),
      this.text("4", (C[0] + A[0]) / 2, C[1] + 24),
      this.text("3", (C[0] + B[0]) / 2 - 16, (C[1] + B[1]) / 2)
    )
  }

  text(content, x, y) {
    const element = this.node("text", { x, y, "text-anchor": "middle", "font-family": "Nunito, sans-serif", "font-weight": 900, "font-size": 18, fill: "#17162b" })
    element.textContent = content
    return element
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
