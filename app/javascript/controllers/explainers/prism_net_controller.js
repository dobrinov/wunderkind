import { Controller } from "@hotwired/stimulus"

// „Призма и пирамида": a right prism on a regular n-gon, cut open and laid
// flat. The side faces make one strip of n rectangles a × h — as long as the
// base's perimeter — and the two bases hang off the second rectangle, so
// M = P · h is read off the strip and S = 2B + M off the whole net. The
// base's area is exact for the square; for the other polygons it is the
// regular polygon's n · a² / (4 · tan(180° / n)), shown rounded.
const SVG = "http://www.w3.org/2000/svg"
// A narrow viewBox, so the labels are still readable when the drawing is
// 290px wide on a phone.
const WIDTH = 360, HEIGHT = 250, FONT = 14
// Where the net goes: room on the left for „h = …", above for „a = …" and
// below for the strip's length.
const AREA = { x: 62, y: 40, w: 286, h: 150 }
// The rectangle the bases are attached to.
const HINGE = 1

export const baseArea = (n, a) => (n * a * a) / (4 * Math.tan(Math.PI / n))

// The regular n-gon of side a standing on the strip's top edge from
// (x, 0) to (x + a, 0), in units, y growing downwards.
export function polygon(n, a, x) {
  const points = [[x, 0], [x + a, 0]]
  for (let k = 1; k <= n - 2; k++) {
    const [px, py] = points[points.length - 1]
    points.push([px + a * Math.cos((-2 * Math.PI * k) / n), py + a * Math.sin((-2 * Math.PI * k) / n)])
  }
  return points
}

// The whole net on the page: the strip's corner, the scale and both bases.
export function layout(n, a, h) {
  const top = polygon(n, a, HINGE * a)
  const bottom = top.map(([x, y]) => [x, h - y])
  const xs = [0, n * a, ...top.map((point) => point[0])]
  const ys = [...top.map((point) => point[1]), ...bottom.map((point) => point[1])]
  const [minX, maxX, minY, maxY] = [Math.min(...xs), Math.max(...xs), Math.min(...ys), Math.max(...ys)]
  const scale = Math.min(AREA.w / (maxX - minX), AREA.h / (maxY - minY))
  const place = ([x, y]) => [
    AREA.x + (AREA.w - (maxX - minX) * scale) / 2 + (x - minX) * scale,
    AREA.y + (AREA.h - (maxY - minY) * scale) / 2 + (y - minY) * scale
  ]
  return { place, scale, top: top.map(place), bottom: bottom.map(place), overhang: Math.max(...top.map((point) => point[0])) - (HINGE + 1) * a }
}

export default class extends Controller {
  static targets = ["sides", "a", "h", "aOut", "hOut", "figure", "lateral", "base", "full", "note"]
  static values = { copy: Object }

  connect() {
    this.n = 4
    this.render()
  }

  choose({ params }) {
    this.n = Number(params.sides)
    for (const button of this.sidesTargets) button.setAttribute("aria-pressed", String(Number(button.dataset.explainerPrismNetSidesParam) === this.n))
    this.render()
  }

  render() {
    const copy = this.copyValue
    const n = this.n
    const [a, h] = [Number(this.aTarget.value), Number(this.hTarget.value)]
    const lateral = n * a * h
    const square = n === 4
    // The base as it is printed, so that S can be worked out from the
    // numbers on the page.
    const base = Math.round(baseArea(n, a) * 100) / 100
    const fmt = (value) => String(Math.round(value * 100) / 100).replace(".", copy.point)
    const fill = (text) => text.replaceAll("%{shape}", copy[`shape_${n}`]).replaceAll("%{n}", n).replaceAll("%{a}", a).replaceAll("%{h}", h)
      .replaceAll("%{P}", n * a).replaceAll("%{M}", lateral).replaceAll("%{B}", square ? a * a : fmt(base))
      .replaceAll("%{S}", square ? 2 * a * a + lateral : fmt(2 * base + lateral))

    this.aOutTarget.textContent = a
    this.hOutTarget.textContent = h
    this.lateralTarget.textContent = fill(copy.lateral)
    this.baseTarget.textContent = fill(square ? copy.base_square : copy.base_other)
    this.fullTarget.textContent = fill(square ? copy.full_square : copy.full_other)
    this.noteTarget.textContent = fill(copy.note)
    this.figureTarget.replaceChildren(this.net(n, a, h, fill(copy.figure)))
  }

  net(n, a, h, label) {
    const svg = this.node("svg", { viewBox: `0 0 ${WIDTH} ${HEIGHT}`, class: "w-full max-w-[520px]", role: "img" })
    svg.setAttribute("aria-label", label)
    const { place, top, bottom } = layout(n, a, h)
    const path = (points) => `M ${points.map(([x, y]) => `${x.toFixed(1)} ${y.toFixed(1)}`).join(" L ")}`
    const line = (from, to, fold) =>
      svg.append(this.node("path", { d: path([from, to]), fill: "none", stroke: "#5048e5", "stroke-width": fold ? 1.2 : 2, "stroke-linecap": "round", ...(fold ? { "stroke-dasharray": "5 5" } : {}) }))

    // The faces: the strip and the two bases.
    svg.append(this.node("path", { d: `${path([[0, 0], [n * a, 0], [n * a, h], [0, h]].map(place))} Z`, fill: "#e2e4ff" }))
    for (const points of [top, bottom]) svg.append(this.node("path", { d: `${path(points)} Z`, fill: "#c9cdff" }))

    // The cut edges solid, the folds dashed: between neighbouring
    // rectangles and where each base hangs on the strip.
    for (const y of [0, h]) {
      line(place([0, y]), place([HINGE * a, y]), false)
      line(place([HINGE * a, y]), place([(HINGE + 1) * a, y]), true)
      line(place([(HINGE + 1) * a, y]), place([n * a, y]), false)
    }
    for (let index = 0; index <= n; index++) line(place([index * a, 0]), place([index * a, h]), index > 0 && index < n)
    for (const points of [top, bottom]) {
      for (let index = 1; index < points.length; index++) line(points[index], points[(index + 1) % points.length], false)
    }

    // The labels: h beside the strip; a over the last rectangle, on a
    // measuring line that shows which edge it is; and the strip's whole
    // length — the perimeter — on a measuring line under the net.
    const measure = (from, to) => {
      const d = `${path([[from[0], from[1] - 4], [from[0], from[1] + 4]])} ${path([from, to])} ${path([[to[0], to[1] - 4], [to[0], to[1] + 4]])}`
      svg.append(this.node("path", { d, fill: "none", stroke: "#312e81", "stroke-width": 1.5, "stroke-linecap": "round" }))
    }
    const [stripLeft, stripTop] = place([0, 0])
    const [stripRight, stripBottom] = place([n * a, h])
    const lastLeft = place([(n - 1) * a, 0])[0]
    const lowest = Math.max(...bottom.map((point) => point[1]))
    this.text(svg, stripLeft - 7, (stripTop + stripBottom) / 2 + 5, `h = ${h}`, "end")
    measure([lastLeft, stripTop - 8], [stripRight, stripTop - 8])
    if (stripRight - lastLeft >= 46) this.text(svg, (lastLeft + stripRight) / 2, stripTop - 15, `a = ${a}`, "middle")
    else this.text(svg, lastLeft, stripTop - 15, `a = ${a}`, "start")
    measure([stripLeft, lowest + 10], [stripRight, lowest + 10])
    this.text(svg, WIDTH / 2, lowest + 28, `P = ${n} · ${a} = ${n * a}`, "middle")
    return svg
  }

  text(svg, x, y, content, anchor) {
    const text = this.node("text", { x: x.toFixed(1), y: y.toFixed(1), "text-anchor": anchor, "font-size": FONT, "font-weight": 900, fill: "#312e81", stroke: "#f5f5fa", "stroke-width": 4, "stroke-linejoin": "round", "paint-order": "stroke" })
    text.textContent = content
    svg.append(text)
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
