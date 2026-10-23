import { Controller } from "@hotwired/stimulus"
import { mathNode } from "../../lib/frac"

// „Какво е дроб?": a pizza cut into d equal slices. The child taps the slices
// they eat, on the pizza or with the numbered buttons under it, and the
// fraction k/d is read off as they go — the top is what they took, the bottom
// is how the pizza was cut.
const SVG = "http://www.w3.org/2000/svg"
const MAX = 12
const C = 120
const R = 108

export default class extends Controller {
  static targets = ["count", "pie", "fraction", "keys", "note"]
  static values = { copy: Object, d: { type: Number, default: 4 } }

  connect() {
    this.eaten = new Set([ 0, 1, 2 ])
    this.render()
  }

  fewer() { this.cut(this.dValue - 1) }
  more() { this.cut(this.dValue + 1) }

  cut(d) {
    this.dValue = Math.max(1, Math.min(MAX, d))
    // Cutting the pizza again keeps the coloured slices that still exist, so
    // the child can watch the same count become a different fraction; slices
    // past the new number are dropped.
    this.eaten = new Set([ ...this.eaten ].filter((i) => i < this.dValue))
    this.render()
  }

  toggle(i) {
    this.eaten.has(i) ? this.eaten.delete(i) : this.eaten.add(i)
    this.render()
  }

  render() {
    const d = this.dValue
    const k = this.eaten.size
    const copy = this.copyValue
    const fill = (text) => text.replaceAll("%{d}", d).replaceAll("%{k}", k)

    this.countTarget.textContent = d
    this.pieTarget.setAttribute("aria-label", fill(d === 1 ? copy.figure_whole : copy.figure))
    this.pieTarget.replaceChildren(this.crust(), ...Array.from({ length: d }, (_, i) => this.slice(i, d)))
    this.fractionTarget.replaceChildren(mathNode(`${k}/${d}`))

    this.keysTarget.replaceChildren(...Array.from({ length: d }, (_, i) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "play-key"
      button.textContent = i + 1
      button.setAttribute("aria-label", copy.slice.replace("%{n}", i + 1))
      button.setAttribute("aria-pressed", this.eaten.has(i))
      button.addEventListener("click", () => this.toggle(i))
      return button
    }))

    const word = copy.words?.[String(d)]
    const said = k === 0 ? copy.none : k === d ? copy.whole : copy.some
    this.noteTarget.textContent = [ fill(said), word ? copy.named.replace("%{word}", word) : null ].filter(Boolean).join(" ")
  }

  crust() {
    return this.node("circle", { cx: C, cy: C, r: R, fill: "#fde68a", stroke: "#b45309", "stroke-width": 4 })
  }

  slice(i, d) {
    const on = this.eaten.has(i)
    const at = (a) => `${C + R * Math.cos(a)} ${C + R * Math.sin(a)}`
    const a0 = -Math.PI / 2 + (2 * Math.PI * i) / d
    const a1 = a0 + (2 * Math.PI) / d
    // One slice of a whole pizza is the full disc; an arc from a point back to
    // itself draws nothing, so it is two half-arcs.
    const d0 = d === 1
      ? `M ${C} ${C - R} A ${R} ${R} 0 1 1 ${C} ${C + R} A ${R} ${R} 0 1 1 ${C} ${C - R} Z`
      : `M ${C} ${C} L ${at(a0)} A ${R} ${R} 0 0 1 ${at(a1)} Z`
    const path = this.node("path", {
      d: d0,
      fill: on ? "#7f7ff7" : "rgb(255 255 255 / 0)",
      stroke: "#ffffff",
      "stroke-width": 3
    })
    path.style.cursor = "pointer"
    path.addEventListener("click", () => this.toggle(i))
    return path
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
