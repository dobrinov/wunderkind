import { Controller } from "@hotwired/stimulus"

// „Формули за съкратено умножение": (a + b)² as a picture. A square of side
// a + b is a square a², a square b² and two rectangles a · b; the working
// under it adds the four areas for the sliders' numbers and sets the total
// beside what a² + b² alone would give.
const SVG = "http://www.w3.org/2000/svg"
const SIDE = 280, LEFT = 60, TOP = 16

export default class extends Controller {
  static targets = ["a", "b", "aOut", "bOut", "figure", "work", "note"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const a = Number(this.aTarget.value)
    const b = Number(this.bTarget.value)
    const fill = (text) => text.replaceAll("%{a}", a).replaceAll("%{b}", b).replaceAll("%{a2}", a * a).replaceAll("%{b2}", b * b)
      .replaceAll("%{ab}", a * b).replaceAll("%{two_ab}", 2 * a * b).replaceAll("%{sum}", (a + b) ** 2).replaceAll("%{wrong}", a * a + b * b)

    this.aOutTarget.textContent = a
    this.bOutTarget.textContent = b
    this.workTarget.textContent = fill(copy.work)
    this.noteTarget.textContent = fill(copy.note)
    this.figureTarget.replaceChildren(this.square(a, b, fill(copy.figure)))
  }

  square(a, b, label) {
    const svg = this.node("svg", { viewBox: "0 0 400 330", class: "w-full max-w-[440px]", role: "img" })
    svg.setAttribute("aria-label", label)

    const cut = (SIDE * a) / (a + b)
    const parts = [
      { x: 0, y: 0, w: cut, h: cut, fill: "#5048e5", ink: "#ffffff", text: `a² = ${a * a}` },
      { x: cut, y: 0, w: SIDE - cut, h: cut, fill: "#c9cdff", ink: "#1f1c5c", text: `ab = ${a * b}` },
      { x: 0, y: cut, w: cut, h: SIDE - cut, fill: "#c9cdff", ink: "#1f1c5c", text: `ab = ${a * b}` },
      { x: cut, y: cut, w: SIDE - cut, h: SIDE - cut, fill: "#312e81", ink: "#ffffff", text: `b² = ${b * b}` }
    ]
    for (const part of parts) {
      svg.append(this.node("rect", { x: LEFT + part.x, y: TOP + part.y, width: part.w, height: part.h, fill: part.fill, stroke: "#ffffff", "stroke-width": 3 }))
      // The label only where it fits; a thin strip keeps its colour and the
      // working underneath says the number.
      if (part.w >= 62 && part.h >= 26) {
        const text = this.node("text", { x: LEFT + part.x + part.w / 2, y: TOP + part.y + part.h / 2 + 6, "text-anchor": "middle", "font-size": 16, "font-weight": 900, fill: part.ink })
        text.textContent = part.text
        svg.append(text)
      }
    }

    // The sides: a and b along the bottom and down the left.
    const sides = [
      { x: LEFT + cut / 2, y: TOP + SIDE + 24, text: `a = ${a}` },
      { x: LEFT + cut + (SIDE - cut) / 2, y: TOP + SIDE + 24, text: `b = ${b}` },
      { x: LEFT - 10, y: TOP + cut / 2 + 6, text: "a", anchor: "end" },
      { x: LEFT - 10, y: TOP + cut + (SIDE - cut) / 2 + 6, text: "b", anchor: "end" }
    ]
    for (const side of sides) {
      const text = this.node("text", { x: side.x, y: side.y, "text-anchor": side.anchor || "middle", "font-size": 17, "font-weight": 900, fill: "#312e81" })
      text.textContent = side.text
      svg.append(text)
    }
    return svg
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
