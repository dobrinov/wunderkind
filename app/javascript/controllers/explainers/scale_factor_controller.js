import { Controller } from "@hotwired/stimulus"

// „Подобни фигури": the 3-4-5 triangle and its copy scaled by k, both on
// the same grid of unit squares so the eye can count. Lengths — each side,
// and so the perimeter — are multiplied by k; the area, being a length times
// a length, by k². The three lines under the drawing say so in numbers.
const SVG = "http://www.w3.org/2000/svg"
// A narrow viewBox, so the numbers on the sides are still readable when the
// drawing is 290px wide on a phone.
const UNIT = 18, LEFT = 26, GAP = 2, BASE_Y = 174, FONT = 14
// The triangle: the right angle bottom left, legs 4 along and 3 up.
const ALONG = 4, UP = 3, SLANT = 5

export default class extends Controller {
  static targets = ["k", "kOut", "figure", "sides", "perimeter", "area", "note"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const k = Number(this.kTarget.value)
    const fmt = (value) => String(Math.round(value * 100) / 100).replace(".", copy.point)
    const fill = (text) => text.replaceAll("%{k2}", fmt(k * k)).replaceAll("%{k}", fmt(k))
      .replaceAll("%{a}", fmt(UP * k)).replaceAll("%{b}", fmt(ALONG * k)).replaceAll("%{c}", fmt(SLANT * k))
      .replaceAll("%{p}", fmt((UP + ALONG + SLANT) * k)).replaceAll("%{s}", fmt(((UP * ALONG) / 2) * k * k))

    this.kOutTarget.textContent = fmt(k)
    this.sidesTarget.textContent = fill(copy.sides)
    this.perimeterTarget.textContent = fill(copy.perimeter)
    this.areaTarget.textContent = fill(copy.area)
    this.noteTarget.textContent = fill(k === 1 ? copy.note_one : copy.note)
    this.figureTarget.replaceChildren(this.drawing(k, fmt, fill(copy.figure)))
  }

  drawing(k, fmt, label) {
    const svg = this.node("svg", { viewBox: "0 0 360 200", class: "w-full max-w-[520px]", role: "img" })
    svg.setAttribute("aria-label", label)

    // The grid: 18 squares along, 9 up — room for the copy at k = 3.
    const columns = ALONG + GAP + ALONG * 3, rows = UP * 3
    for (let column = 0; column <= columns; column++) {
      const x = LEFT + column * UNIT
      svg.append(this.node("line", { x1: x, y1: BASE_Y - rows * UNIT, x2: x, y2: BASE_Y, stroke: "#c5c5d6", "stroke-width": 1 }))
    }
    for (let row = 0; row <= rows; row++) {
      const y = BASE_Y - row * UNIT
      svg.append(this.node("line", { x1: LEFT, y1: y, x2: LEFT + columns * UNIT, y2: y, stroke: "#c5c5d6", "stroke-width": 1 }))
    }

    this.triangle(svg, LEFT, 1, fmt, "#e2e4ff", "#9a9ab0", "#50506b")
    this.triangle(svg, LEFT + (ALONG + GAP) * UNIT, k, fmt, "#c9cdff", "#5048e5", "#312e81")
    return svg
  }

  // The triangle with its right angle at (x, BASE_Y), scaled by k, and its
  // three sides labelled: under the base, left of the upright, off the slant.
  triangle(svg, x, k, fmt, fill, stroke, ink) {
    const [along, up] = [ALONG * k * UNIT, UP * k * UNIT]
    svg.append(this.node("path", { d: `M ${x} ${BASE_Y} L ${x + along} ${BASE_Y} L ${x} ${BASE_Y - up} Z`, fill, stroke, "stroke-width": 2.5, "stroke-linejoin": "round" }))
    this.text(svg, x + along / 2, BASE_Y + 17, fmt(ALONG * k), "middle", ink)
    this.text(svg, x - 5, BASE_Y - up / 2 + 5, fmt(UP * k), "end", ink)
    // Off the middle of the slant, along its outward normal (3, −4) / 5.
    this.text(svg, x + along / 2 + 6, BASE_Y - up / 2 - 5, fmt(SLANT * k), "start", ink)
  }

  text(svg, x, y, content, anchor, colour) {
    const text = this.node("text", { x, y, "text-anchor": anchor, "font-size": FONT, "font-weight": 900, fill: colour, stroke: "#f5f5fa", "stroke-width": 4, "stroke-linejoin": "round", "paint-order": "stroke" })
    text.textContent = content
    svg.append(text)
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
