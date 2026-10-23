import { Controller } from "@hotwired/stimulus"

// „Какво е тригонометрия?": the height of a tree 20 m away from the angle up
// to its top, height = 20 · tg α. One scale for both directions, or the drawn
// line would not make the angle on the slider: 6 px per metre fits the top of
// the slider (70°, about 55 m) above the ground line.
const SCALE = 6
const DISTANCE = 20
const GROUND = 350
const EYE = 60
const TREE = EYE + DISTANCE * SCALE

export default class extends Controller {
  static targets = ["slider", "degrees", "figure", "trunk", "crown", "sight", "formula"]
  static values = { copy: Object }

  connect() {
    this.render(Number(this.sliderTarget.value))
  }

  slide() { this.render(Number(this.sliderTarget.value)) }

  render(degrees) {
    const copy = this.copyValue
    const tan = Math.tan((degrees * Math.PI) / 180)
    const height = DISTANCE * tan
    const top = GROUND - height * SCALE
    const heightText = height.toFixed(1).replace(".", ",")

    this.set(this.trunkTarget, { x: TREE - 6, y: top, height: GROUND - top })
    this.set(this.crownTarget, { cx: TREE, cy: top })
    this.set(this.sightTarget, { x2: TREE, y2: top })
    this.degreesTarget.textContent = `${degrees}°`
    this.figureTarget.setAttribute("aria-label", copy.figure.replace("%{deg}", degrees).replace("%{height}", heightText))
    this.formulaTarget.textContent = copy.formula.replace("%{deg}", degrees)
      // Three decimals, so the product of the numbers shown is the height shown:
      // with two, 20 · 2,14 read „≈ 42,9".
      .replace("%{tan}", tan.toFixed(3).replace(".", ",")).replace("%{height}", heightText)
  }

  set(element, attributes) {
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
  }
}
