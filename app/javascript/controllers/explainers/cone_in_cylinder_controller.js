import { Controller } from "@hotwired/stimulus"

// „Цилиндър, конус и кълбо": the third in the cone's volume as an
// experiment. A cylinder and a cone share a radius and a height; the cone,
// held point down and full of water, is poured into the cylinder, and the
// level rises by a third of the height each time — three pours and it is
// full, for every r and h. The working beside it gives both volumes in terms
// of π and rounded. Both solids are drawn the way the site draws them: side
// on, the circles flattened into ellipses, the hidden half of a rim dashed.
const SVG = "http://www.w3.org/2000/svg"
// A narrow viewBox, so the labels are still readable when the drawing is
// 290px wide on a phone.
const WIDTH = 360, HEIGHT = 246, BASE_Y = 200, FONT = 14
const CYLINDER_X = 118, CONE_X = 290, FLAT = 0.3
const POURS = 3

// Pixels per unit, so the widest and the tallest pair both fit.
export const scaleFor = (r, h) => Math.min(62 / r, 140 / h)

// How flat the circles are drawn: the usual 0.3, less for a low solid, so
// a cone's point always stands clear of its own rim.
export const rimFor = (rx, tall) => Math.min(rx * FLAT, tall * 0.35)

// „12π", „50π/3", „π": a whole number of π over 1 or 3.
export function inPi(numerator, denominator) {
  if (numerator % denominator === 0) return numerator / denominator === 1 ? "π" : `${numerator / denominator}π`
  return `${numerator === 1 ? "" : numerator}π/${denominator}`
}

export default class extends Controller {
  static targets = ["r", "h", "rOut", "hOut", "figure", "pour", "reset", "status", "cone", "cylinder"]
  static values = { copy: Object }

  connect() {
    this.poured = 0
    this.render()
  }

  pour() {
    if (this.poured < POURS) this.poured += 1
    this.render()
    // „Излей" has just switched itself off: hand the keyboard to the one
    // thing left to press.
    if (this.poured === POURS) this.resetTarget.focus()
  }

  reset() {
    this.poured = 0
    this.render()
  }

  // New sizes are a new experiment.
  resize() {
    this.poured = 0
    this.render()
  }

  render() {
    const copy = this.copyValue
    const [r, h] = [Number(this.rTarget.value), Number(this.hTarget.value)]
    const product = r * r * h
    const fmt = (value) => String(Math.round(value * 100) / 100).replace(".", copy.point)
    const fill = (text) => text.replaceAll("%{r}", r).replaceAll("%{h}", h).replaceAll("%{poured}", this.poured)
      .replaceAll("%{cone_pi}", inPi(product, 3)).replaceAll("%{cylinder_pi}", inPi(product, 1))
      .replaceAll("%{cone}", fmt((Math.PI * product) / 3)).replaceAll("%{cylinder}", fmt(Math.PI * product))

    this.rOutTarget.textContent = r
    this.hOutTarget.textContent = h
    this.pourTarget.disabled = this.poured === POURS
    this.statusTarget.textContent = fill(copy[`status_${this.poured}`])
    this.coneTarget.textContent = fill(copy.cone)
    this.cylinderTarget.textContent = fill(copy.cylinder)
    this.figureTarget.replaceChildren(this.drawing(r, h, fill(copy.figure)))
  }

  drawing(r, h, label) {
    const copy = this.copyValue
    const svg = this.node("svg", { viewBox: `0 0 ${WIDTH} ${HEIGHT}`, class: "w-full max-w-[520px]", role: "img" })
    svg.setAttribute("aria-label", label)
    const scale = scaleFor(r, h)
    const [rx, tall] = [r * scale, h * scale]
    const ry = rimFor(rx, tall)
    const top = BASE_Y - tall
    const outline = { fill: "none", stroke: "#5048e5", "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round" }
    // Half an ellipse from its left end to its right: the near half (below
    // the centre) or the far half (above it).
    const half = (cx, cy, near) => `M ${cx - rx} ${cy} A ${rx} ${ry} 0 0 ${near ? 0 : 1} ${cx + rx} ${cy}`

    // The cylinder: the water first, then the glass over it.
    const level = BASE_Y - (tall * this.poured) / POURS
    if (this.poured > 0) {
      svg.append(this.node("path", { d: `M ${CYLINDER_X - rx} ${level} L ${CYLINDER_X - rx} ${BASE_Y} A ${rx} ${ry} 0 0 0 ${CYLINDER_X + rx} ${BASE_Y} L ${CYLINDER_X + rx} ${level} A ${rx} ${ry} 0 0 1 ${CYLINDER_X - rx} ${level} Z`, fill: "#a5aaff" }))
      svg.append(this.node("ellipse", { cx: CYLINDER_X, cy: level, rx, ry, fill: "#c9cdff", stroke: "#5048e5", "stroke-width": 1.5 }))
    }
    svg.append(this.node("path", { d: half(CYLINDER_X, BASE_Y, false), ...outline, "stroke-width": 1.5, "stroke-dasharray": "5 5" }))
    svg.append(this.node("path", { d: half(CYLINDER_X, BASE_Y, true), ...outline }))
    svg.append(this.node("ellipse", { cx: CYLINDER_X, cy: top, rx, ry, ...outline }))
    for (const x of [CYLINDER_X - rx, CYLINDER_X + rx]) svg.append(this.node("line", { x1: x, y1: top, x2: x, y2: BASE_Y, ...outline }))
    // The thirds, ticked on the far wall of the glass.
    for (const third of [1, 2]) {
      const y = BASE_Y - (tall * third) / POURS
      svg.append(this.node("line", { x1: CYLINDER_X + rx - 8, y1: y, x2: CYLINDER_X + rx, y2: y, stroke: "#312e81", "stroke-width": 2.5, "stroke-linecap": "round" }))
    }

    // The cone, point down: full until the third pour has emptied it.
    if (this.poured < POURS) {
      svg.append(this.node("path", { d: `M ${CONE_X} ${BASE_Y} L ${CONE_X - rx} ${top} A ${rx} ${ry} 0 0 0 ${CONE_X + rx} ${top} Z`, fill: "#a5aaff" }))
      svg.append(this.node("ellipse", { cx: CONE_X, cy: top, rx, ry, fill: "#c9cdff" }))
    }
    svg.append(this.node("ellipse", { cx: CONE_X, cy: top, rx, ry, ...outline }))
    svg.append(this.node("path", { d: `M ${CONE_X - rx} ${top} L ${CONE_X} ${BASE_Y} L ${CONE_X + rx} ${top}`, ...outline }))
    svg.append(this.node("line", { x1: CONE_X, y1: top, x2: CONE_X + rx, y2: top, stroke: "#312e81", "stroke-width": 1.5, "stroke-dasharray": "4 4" }))

    // The sizes they share, and which solid is which.
    this.text(svg, CYLINDER_X - rx - 7, (top + BASE_Y) / 2 + 5, `h = ${h}`, "end", "#312e81")
    this.text(svg, CONE_X + rx / 2, top - ry - 7, `r = ${r}`, "middle", "#312e81")
    this.text(svg, CYLINDER_X, BASE_Y + 38, copy.cylinder_name, "middle", "#50506b")
    this.text(svg, CONE_X, BASE_Y + 38, copy.cone_name, "middle", "#50506b")
    return svg
  }

  text(svg, x, y, content, anchor, colour) {
    const text = this.node("text", { x, y, "text-anchor": anchor, "font-size": FONT, "font-weight": 900, fill: colour })
    text.textContent = content
    svg.append(text)
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
