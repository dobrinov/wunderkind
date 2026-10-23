import { Controller } from "@hotwired/stimulus"

// „Какво е тригонометрия?": a right triangle whose hypotenuse is 1, drawn
// inside a quarter circle of radius 1. Its height is the sine of the angle and
// its width the cosine — the definitions, read off the picture.
const R = 280
const ORIGIN = [60, 300]
const ARC = 44
const SPECIAL = [30, 45, 60]

export default class extends Controller {
  static targets = ["slider", "degrees", "preset", "figure", "triangle", "sine", "cosine", "arc", "corner", "alpha",
                    "sineLabel", "cosineLabel", "hypotenuseLabel", "angleText", "sinValue", "cosValue", "tanValue", "note"]
  static values = { copy: Object }

  connect() {
    this.render(Number(this.sliderTarget.value))
  }

  slide() { this.render(Number(this.sliderTarget.value)) }

  preset({ params: { degrees } }) {
    this.sliderTarget.value = degrees
    this.render(degrees)
  }

  render(degrees) {
    const copy = this.copyValue
    const radians = (degrees * Math.PI) / 180
    const sin = Math.sin(radians)
    const cos = Math.cos(radians)
    const [ox, oy] = ORIGIN
    const px = ox + R * cos
    const py = oy - R * sin

    this.triangleTarget.setAttribute("points", `${ox},${oy} ${px},${oy} ${px},${py}`)
    this.set(this.sineTarget, { x1: px, x2: px, y2: py })
    this.set(this.cosineTarget, { x2: px })
    this.arcTarget.setAttribute("d", `M ${ox + ARC} ${oy} A ${ARC} ${ARC} 0 0 0 ${ox + ARC * cos} ${oy - ARC * sin}`)
    this.cornerTarget.setAttribute("d", `M ${px - 14} ${oy} V ${oy - 14} H ${px}`)
    // The α sits on the angle's bisector just past its arc, so it stays inside
    // the angle however narrow the angle gets.
    const half = radians / 2
    this.set(this.alphaTarget, { x: ox + (ARC + 18) * Math.cos(half), y: oy - (ARC + 18) * Math.sin(half) + 6 })
    this.set(this.sineLabelTarget, { x: px + 10, y: (py + oy) / 2 })
    this.set(this.cosineLabelTarget, { x: (ox + px) / 2 })
    this.set(this.hypotenuseLabelTarget, { x: (ox + px) / 2 - 10, y: (oy + py) / 2 - 6 })

    const sinText = this.number(sin, 3)
    const cosText = this.number(cos, 3)
    this.figureTarget.setAttribute("aria-label", copy.figure.replace("%{deg}", degrees)
      .replace("%{sin}", this.number(sin, 2)).replace("%{cos}", this.number(cos, 2)))
    this.degreesTarget.textContent = `${degrees}°`
    this.angleTextTargets.forEach((target) => { target.textContent = `${degrees}°` })
    this.sinValueTarget.textContent = sinText
    this.cosValueTarget.textContent = cosText
    this.tanValueTarget.textContent = this.number(Math.tan(radians), 3)
    this.presetTargets.forEach((button, i) => button.setAttribute("aria-pressed", SPECIAL[i] === degrees))
    this.noteTarget.textContent = SPECIAL.includes(degrees) ? copy[`note_${degrees}`] : copy.note
  }

  set(element, attributes) {
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
  }

  // A decimal comma, as the problems write it.
  number(value, digits) {
    return value.toFixed(digits).replace(".", ",")
  }
}
