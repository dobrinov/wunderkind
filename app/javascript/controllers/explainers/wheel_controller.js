import { Controller } from "@hotwired/stimulus"

// „Окръжност и числото π": a wheel rolled along a line. The blue path is the
// part of the circumference already laid down, and an orange tick marks every
// diameter — one full turn always ends just past the third, at π diameters.
const SVG = "http://www.w3.org/2000/svg"
// Pixels per cm: small enough that a 5 cm wheel starting one radius in from the
// left (75 px) and rolled all the way (5π cm, plus its radius again) still fits
// in the 640-wide figure.
const SCALE = 30
const START = 80
const GROUND = 170

export default class extends Controller {
  static targets = ["roll", "rollOut", "diameter", "diameterOut", "figure", "rolled", "ratio"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const percent = Number(this.rollTarget.value)
    const d = Number(this.diameterTarget.value)
    const r = (d * SCALE) / 2
    const circumference = Math.PI * d
    const rolled = (circumference * percent) / 100
    const cx = START + rolled * SCALE
    const cy = GROUND - r
    const turned = (rolled * SCALE) / r

    this.rollOutTarget.textContent = copy.percent.replace("%{value}", percent)
    this.diameterOutTarget.textContent = copy.centimetres.replace("%{value}", d)

    const parts = [this.node("line", { x1: 10, y1: GROUND, x2: 630, y2: GROUND, stroke: "#c5c5d6", "stroke-width": 3 })]
    for (let k = 1; k * d <= circumference; k++) {
      const x = START + k * d * SCALE
      parts.push(this.node("line", { x1: x, y1: GROUND - 10, x2: x, y2: GROUND + 12, stroke: "#ea580c", "stroke-width": 3 }))
      const label = this.node("text", { x, y: GROUND + 28, "text-anchor": "middle", "font-size": 13, "font-weight": 900, fill: "#9a3412" })
      label.textContent = copy.tick.replace("%{k}", k)
      parts.push(label)
    }
    if (rolled > 0) {
      parts.push(this.node("line", { x1: START, y1: GROUND, x2: cx, y2: GROUND, stroke: "#5048e5", "stroke-width": 6, "stroke-linecap": "round" }))
    }
    parts.push(
      this.node("circle", { cx, cy, r, fill: "#e2e4ff", stroke: "#5048e5", "stroke-width": 4 }),
      // A spoke from the centre to the point that started on the ground shows
      // the wheel turning, not sliding.
      this.node("line", { x1: cx, y1: cy, x2: cx - r * Math.sin(turned), y2: cy + r * Math.cos(turned), stroke: "#ea580c", "stroke-width": 3 })
    )
    this.figureTarget.replaceChildren(...parts)
    this.figureTarget.setAttribute("aria-label", copy.figure.replace("%{d}", d).replace("%{percent}", percent))

    this.rolledTarget.textContent = copy.rolled.replace("%{value}", this.decimal(rolled, 1))
    this.ratioTarget.textContent = percent === 100
      ? copy.full.replace("%{value}", this.decimal(circumference, 2)).replace("%{d}", d)
      : copy.diameters.replace("%{value}", this.decimal(rolled / d, 2))
  }

  decimal(value, places) {
    return value.toFixed(places).replace(".", ",")
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
