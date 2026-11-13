import { Controller } from "@hotwired/stimulus"

// „Синусова и косинусова теорема": two sides a and b and the angle γ between
// them, the case the cosine rule is for. The triangle is drawn to scale with
// C at the angle, and the working goes the way it would on paper: c from the
// cosine rule, then one angle from the sine rule — always the one opposite
// the shorter of a and b, which is acute, so arcsin cannot pick the wrong one
// of its two answers — and the area.
//
// Every line is worked from the numbers the line before it printed (cos γ to
// four places, c² and c to two, the sine to four), so a reader with a
// calculator gets what is on the screen. Whether a value is written after =
// or after ≈ is decided by the true value, not the printed one.
const SVG = "http://www.w3.org/2000/svg"
const W = 340, H = 250, PAD_X = 40, PAD_TOP = 34, PAD_BOTTOM = 38
const HALO = { stroke: "#f5f5fa", "stroke-width": 5, "stroke-linejoin": "round", "paint-order": "stroke" }

const round = (value, places) => Math.round(value * 10 ** places) / 10 ** places
const exact = (value, places) => Math.abs(value - round(value, places)) < 1e-9

export function solve(a, b, gamma) {
  const rad = (gamma * Math.PI) / 180
  const sin = Math.sin(rad)
  const truth = { cos: Math.cos(rad) }
  truth.c2 = a * a + b * b - 2 * a * b * truth.cos
  truth.c = Math.sqrt(truth.c2)
  const short = a <= b ? { letter: "α", other: "β", side: "a", length: a } : { letter: "β", other: "α", side: "b", length: b }
  truth.ratio = (short.length * sin) / truth.c
  truth.angle = (Math.asin(Math.min(1, truth.ratio)) * 180) / Math.PI

  // c² as printed is worked from the printed cosine, c from the printed c²,
  // and the angle from the printed sine. The sine itself is the true one
  // (not a quotient by the rounded c), and an angle that is exact is printed
  // exactly — so an isosceles triangle keeps its two equal angles.
  const cos = round(truth.cos, 4)
  const c2 = round(a * a + b * b - 2 * a * b * cos, 2)
  const c = round(Math.sqrt(c2), 2)
  const ratio = round(truth.ratio, 4)
  const angle = round(exact(truth.angle, 1) ? truth.angle : (Math.asin(Math.min(1, ratio)) * 180) / Math.PI, 1)
  const exactC = exact(truth.c2, 2) && exact(truth.c, 2)

  return {
    rad, short, truth, cos, c2, c, ratio, angle,
    third: round(180 - gamma - angle, 1),
    area: (a * b * sin) / 2,
    exact: {
      cos: exact(truth.cos, 4), c2: exact(truth.c2, 2), c: exactC,
      ratio: exact(truth.ratio, 4), angle: exact(truth.angle, 1), area: exact((a * b * sin) / 2, 2)
    }
  }
}

// Where everything lands in the viewBox: C at the angle, B along the base, A
// above, scaled to fill the box inside its padding. γ is marked the way the
// corner has room for: an arc with the letter beyond it on the bisector; in a
// wide, shallow corner the letter first and the arc around it; and where the
// side c passes too close for an arc, the letter alone. The arc never reaches
// the side c, and the letter keeps clear of all three sides.
export function layout(a, b, rad) {
  const ax = b * Math.cos(rad), ay = b * Math.sin(rad)
  const minX = Math.min(0, ax), maxX = Math.max(a, ax)
  const boxW = W - 2 * PAD_X, boxH = H - PAD_TOP - PAD_BOTTOM
  const scale = Math.min(boxW / (maxX - minX), boxH / ay)
  const left = (W - (maxX - minX) * scale) / 2 - minX * scale
  const base = H - PAD_BOTTOM - (boxH - ay * scale) / 2
  const A = { x: left + ax * scale, y: base - ay * scale }, B = { x: left + a * scale, y: base }, C = { x: left, y: base }

  const c = Math.hypot(A.x - B.x, A.y - B.y)
  const altitude = (a * scale * ay * scale) / c          // from C onto side c
  const bisector = ((2 * a * b * Math.cos(rad / 2)) / (a + b)) * scale
  const shorter = Math.min(a, b) * scale
  const along = (reach) => ({ x: C.x + reach * Math.cos(rad / 2), y: C.y - reach * Math.sin(rad / 2) })
  const clear = Math.max(11 / Math.sin(rad / 2), 13)     // the nearest the letter fits between the sides

  const outside = Math.max(20 + 12, clear)
  if (outside + 11 <= bisector && 20 <= 0.8 * altitude && 20 <= 0.45 * shorter) return { scale, A, B, C, radius: 20, letter: along(outside) }
  const around = clear + 11
  if (around <= 0.85 * altitude && around <= 0.6 * shorter) return { scale, A, B, C, radius: around, letter: along(clear) }
  if (clear + 10 <= bisector) return { scale, A, B, C, radius: 0, letter: along(clear) }
  return { scale, A, B, C, radius: Math.min(20, 0.45 * shorter, 0.8 * altitude), letter: null }
}

export default class extends Controller {
  static targets = ["a", "b", "gamma", "aOut", "bOut", "gammaOut", "figure", "numbers", "side", "note", "angle", "area"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const a = Number(this.aTarget.value)
    const b = Number(this.bTarget.value)
    const gamma = Number(this.gammaTarget.value)
    const found = solve(a, b, gamma)

    const num = (value, places) => String(round(value, places) + 0).replace(".", copy.point).replace("-", "−")
    const rel = (isExact) => (isExact ? "=" : "≈")
    const values = {
      a, b, gamma,
      a2: a * a, b2: b * b, two_ab: 2 * a * b, sum: a * a + b * b,
      cos: found.cos < 0 ? `(${num(found.cos, 4)})` : num(found.cos, 4), rel_cos: rel(found.exact.cos),
      c2: num(found.c2, 2), rel_c2: rel(found.exact.c2),
      c: num(found.c, 2), rel_c: rel(found.exact.c),
      letter: found.short.letter, other: found.short.other, side: found.short.side, length: found.short.length,
      ratio: num(found.ratio, 4), rel_ratio: rel(found.exact.ratio),
      angle: num(found.angle, 1), rel_angle: rel(found.exact.angle), third: num(found.third, 1),
      area: num(found.area, 2), rel_area: rel(found.exact.area)
    }
    const fill = (text) => Object.entries(values).reduce((out, [key, value]) => out.replaceAll(`%{${key}}`, value), text)

    this.aOutTarget.textContent = a
    this.bOutTarget.textContent = b
    this.gammaOutTarget.textContent = `${gamma}°`
    this.numbersTarget.textContent = fill(copy.numbers)
    this.sideTarget.textContent = fill(copy.side)
    this.noteTarget.textContent = fill(gamma === 90 ? copy.note_right : gamma < 90 ? copy.note_acute : copy.note_obtuse)
    this.angleTarget.textContent = fill(copy.angle)
    this.areaTarget.textContent = fill(copy.area)
    this.figureTarget.replaceChildren(this.triangle(a, b, gamma, found.rad, fill(copy.figure)))
  }

  triangle(a, b, gamma, rad, label) {
    const svg = this.node("svg", { viewBox: `0 0 ${W} ${H}`, class: "w-full max-w-[440px]", role: "img" })
    svg.setAttribute("aria-label", label)
    const { A, B, C, radius, letter } = layout(a, b, rad)

    svg.append(this.node("polygon", { points: [A, B, C].map((point) => `${point.x},${point.y}`).join(" "), fill: "#e2e4ff", stroke: "#312e81", "stroke-width": 2.5, "stroke-linejoin": "round" }))
    // The side being found, c, in the emphasis colour.
    svg.append(this.node("line", { x1: A.x, y1: A.y, x2: B.x, y2: B.y, stroke: "#5048e5", "stroke-width": 4.5, "stroke-linecap": "round" }))

    // γ at C: the small square at a right angle, otherwise an arc from the
    // base round to the side b.
    const up = { x: Math.cos(rad), y: -Math.sin(rad) }
    if (radius === 0) {
      // No room for an arc: the letter alone marks the angle.
    } else if (gamma === 90) {
      const side = Math.min(radius * 0.7, 14)
      svg.append(this.node("path", { d: `M ${C.x + side} ${C.y} L ${C.x + side} ${C.y - side} L ${C.x} ${C.y - side}`, fill: "none", stroke: "#5048e5", "stroke-width": 2 }))
    } else {
      svg.append(this.node("path", { d: `M ${C.x + radius} ${C.y} A ${radius} ${radius} 0 0 0 ${C.x + radius * up.x} ${C.y + radius * up.y}`, fill: "none", stroke: "#5048e5", "stroke-width": 2 }))
    }
    if (letter) svg.append(this.text("γ", letter.x, letter.y + 5, "#5048e5", 15, false))

    // Vertex letters pushed away from the middle of the triangle; side
    // letters pushed off their side, away from the opposite vertex.
    const middle = { x: (A.x + B.x + C.x) / 3, y: (A.y + B.y + C.y) / 3 }
    for (const [name, vertex] of [["A", A], ["B", B], ["C", C]]) {
      const length = Math.hypot(vertex.x - middle.x, vertex.y - middle.y) || 1
      svg.append(this.text(name, vertex.x + (17 * (vertex.x - middle.x)) / length, vertex.y + (17 * (vertex.y - middle.y)) / length + 5, "#50506b", 15, true))
    }
    for (const [name, from, to, opposite, ink] of [["a", B, C, A, "#312e81"], ["b", C, A, B, "#312e81"], ["c", A, B, C, "#5048e5"]]) {
      const mid = { x: (from.x + to.x) / 2, y: (from.y + to.y) / 2 }
      const length = Math.hypot(to.x - from.x, to.y - from.y) || 1
      let normal = { x: -(to.y - from.y) / length, y: (to.x - from.x) / length }
      if (normal.x * (opposite.x - mid.x) + normal.y * (opposite.y - mid.y) > 0) normal = { x: -normal.x, y: -normal.y }
      svg.append(this.text(name, mid.x + 15 * normal.x, mid.y + 15 * normal.y + 5, ink, 16, true))
    }
    return svg
  }

  text(content, x, y, ink, size, halo) {
    const text = this.node("text", { x, y, "text-anchor": "middle", "font-size": size, "font-weight": 900, "font-style": "italic", fill: ink, ...(halo ? HALO : {}) })
    text.textContent = content
    return text
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
