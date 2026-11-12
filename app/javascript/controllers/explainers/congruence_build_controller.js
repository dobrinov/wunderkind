import { Controller } from "@hotwired/stimulus"

// „Еднакви триъгълници": a criterion as a recipe. Under each of the three
// criteria the reader sets three values and gets exactly one triangle — drawn
// above a copy that is flipped and turned, because „the same triangle" has
// to survive both. The given parts are drawn heavy (sides) or marked with an
// arc (angles) and labelled; the parts that follow from them are listed
// underneath. Values that close into no triangle (a side as long as the
// other two together, two angles that leave nothing of the 180°) draw
// nothing and say why.
//
// The two triangles are stacked in a narrow viewBox so the labels are still
// readable on a phone, and every label is placed by trying positions in turn
// and taking the first that is clear of the labels already there: a thin
// triangle has no room inside a 20° angle, so its size goes outside the
// vertex instead, and a label with no room anywhere is left out — the value
// is still on its slider and in the sentence below.
const SVG = "http://www.w3.org/2000/svg"
const WIDTH = 360, HEIGHT = 420, FONT = 14
// Where each triangle goes: a box with room around it for the labels.
const BOXES = [{ x: 52, y: 44, w: 256, h: 128 }, { x: 52, y: 250, w: 256, h: 128 }]
const TURN = (140 * Math.PI) / 180
const ARC = 16

const side = (name, value, min = 3) => ({ name, value, min, max: 9, step: 1, angle: false })
const angle = (name, value, max) => ({ name, value, min: 20, max, step: 5, angle: true })

// The article's own example first: AB = 6, AC = 5, angle A = 50°. An angle
// is named by its vertex alone here; the word for it comes from the copy.
export const CRITERIA = {
  sas: [side("AB", 6), side("AC", 5), angle("A", 50, 150)],
  asa: [side("AB", 6), angle("A", 50, 120), angle("B", 60, 120)],
  sss: [side("AB", 6, 2), side("BC", 5, 2), side("AC", 4, 2)]
}

const radians = (degrees) => (degrees * Math.PI) / 180
const degrees = (value) => (value * 180) / Math.PI

// The triangle the three values make, with A at the origin and B along the
// x axis — or the reason there is none.
export function solve(criterion, [p, q, r]) {
  let c, b, A
  if (criterion === "sas") {
    [c, b, A] = [p, q, radians(r)]
  } else if (criterion === "asa") {
    if (q + r >= 180) return { error: "asa", alpha: q, beta: r, sum: q + r }
    c = p
    A = radians(q)
    b = (c * Math.sin(radians(r))) / Math.sin(radians(180 - q - r))
  } else {
    const [long, x, y] = [p, q, r].sort((first, second) => second - first)
    if (long >= x + y) return { error: "sss", long, x, y, sum: x + y }
    ;[c, b] = [p, r]
    A = Math.acos((b * b + c * c - q * q) / (2 * b * c))
  }
  const points = { A: [0, 0], B: [c, 0], C: [b * Math.cos(A), b * Math.sin(A)] }
  const a = Math.hypot(points.C[0] - c, points.C[1])
  const B = Math.acos((a * a + c * c - b * b) / (2 * a * c))
  return { points, sides: { AB: c, BC: a, AC: b }, angles: { A: degrees(A), B: degrees(B), C: 180 - degrees(A) - degrees(B) } }
}

// The two triangles on the page: the same scale for both, each centred in
// its box. The second is the first mirrored and turned.
export function place(points) {
  const first = Object.values(points).map(([x, y]) => [x, -y])
  const second = first.map(([x, y]) => [-x * Math.cos(TURN) - y * Math.sin(TURN), -x * Math.sin(TURN) + y * Math.cos(TURN)])
  const boxOf = (list) => {
    const xs = list.map((point) => point[0]), ys = list.map((point) => point[1])
    return { x: Math.min(...xs), y: Math.min(...ys), w: Math.max(...xs) - Math.min(...xs), h: Math.max(...ys) - Math.min(...ys) }
  }
  const bounds = [first, second].map(boxOf)
  const scale = Math.min(...bounds.map((bound, index) => Math.min(BOXES[index].w / bound.w, BOXES[index].h / bound.h)))
  return [first, second].map((list, index) => {
    const [bound, box] = [bounds[index], BOXES[index]]
    return list.map(([x, y]) => [
      box.x + (box.w - bound.w * scale) / 2 + (x - bound.x) * scale,
      box.y + (box.h - bound.h * scale) / 2 + (y - bound.y) * scale
    ])
  })
}

const unit = ([x, y]) => { const length = Math.hypot(x, y) || 1; return [x / length, y / length] }
const along = (from, direction, distance) => [from[0] + direction[0] * distance, from[1] + direction[1] * distance]
const turned = ([x, y], degreesBy) => { const by = radians(degreesBy); return [x * Math.cos(by) - y * Math.sin(by), x * Math.sin(by) + y * Math.cos(by)] }

// The room a label takes, centred on a point.
const boxAt = ([x, y], text) => {
  const [w, h] = [text.length * FONT * 0.62 + 4, FONT + 2]
  return { x1: x - w / 2, x2: x + w / 2, y1: y - h / 2, y2: y + h / 2 }
}
const clash = (a, b) => a.x1 < b.x2 && b.x1 < a.x2 && a.y1 < b.y2 && b.y1 < a.y2

// Every label of both triangles: { at, text, kind } for each one that found
// room. `names` are the given parts (CRITERIA names), `values` their sizes.
// Placed in order of need — the vertices, the given sides, the given angles —
// each at the first of its positions that is on the page and clear of the
// vertices and of every label before it.
export function labels(triangles, names, values) {
  const taken = []
  for (const corners of triangles) for (const [x, y] of corners) taken.push({ x1: x - 3, x2: x + 3, y1: y - 3, y2: y + 3 })
  const placed = []
  const put = (positions, text, kind) => {
    for (const at of positions) {
      const box = boxAt(at, text)
      if (box.x1 < 2 || box.x2 > WIDTH - 2 || box.y1 < 2 || box.y2 > HEIGHT - 2 || taken.some((other) => clash(box, other))) continue
      taken.push(box)
      placed.push({ at, text, kind })
      return
    }
  }
  const shapes = triangles.map((corners, index) => {
    const vertex = { A: corners[0], B: corners[1], C: corners[2] }
    const geometry = {}
    for (const letter of ["A", "B", "C"]) {
      const [first, second] = ["A", "B", "C"].filter((other) => other !== letter).map((other) => unit([vertex[other][0] - vertex[letter][0], vertex[other][1] - vertex[letter][1]]))
      const reach = Math.min(...["A", "B", "C"].filter((other) => other !== letter).map((other) => Math.hypot(vertex[other][0] - vertex[letter][0], vertex[other][1] - vertex[letter][1])))
      const inward = unit([first[0] + second[0], first[1] + second[1]])
      const half = Math.acos(Math.max(-1, Math.min(1, first[0] * second[0] + first[1] * second[1]))) / 2
      geometry[letter] = { at: vertex[letter], inward, outward: [-inward[0], -inward[1]], half, reach }
    }
    return { vertex, geometry, suffix: index === 1 ? "₁" : "" }
  })

  for (const { geometry, suffix } of shapes) {
    for (const letter of ["A", "B", "C"]) {
      const { at, outward } = geometry[letter]
      put([15, 22, 30].map((distance) => along(at, outward, distance)), `${letter}${suffix}`, "vertex")
    }
  }
  for (const { vertex } of shapes) {
    for (const name of ["AB", "BC", "AC"]) {
      if (!names.includes(name)) continue
      const [from, to] = [vertex[name[0]], vertex[name[1]]]
      const third = vertex[["A", "B", "C"].find((letter) => !name.includes(letter))]
      const middle = [(from[0] + to[0]) / 2, (from[1] + to[1]) / 2]
      const normal = unit([-(to[1] - from[1]), to[0] - from[0]])
      const away = (third[0] - middle[0]) * normal[0] + (third[1] - middle[1]) * normal[1] > 0 ? [-normal[0], -normal[1]] : normal
      put([13, 24, 36].map((distance) => along(middle, away, distance)), String(values[names.indexOf(name)]), "side")
    }
  }
  for (const { geometry } of shapes) {
    for (const letter of ["A", "B", "C"]) {
      if (!names.includes(letter)) continue
      const { at, inward, outward, half, reach } = geometry[letter]
      // Inside the angle only where its arms are far enough apart to hold
      // the number, and the triangle is long enough to reach that far.
      const inside = Math.max(30, 20 / Math.sin(half))
      const positions = inside <= reach * 0.6 ? [along(at, inward, inside)] : []
      positions.push(...[34, 44, 56].map((distance) => along(at, outward, distance)))
      positions.push(...[50, -50, 80, -80].map((by) => along(at, turned(outward, by), 34)))
      put(positions, `${values[names.indexOf(letter)]}°`, "angle")
    }
  }
  return placed
}

export default class extends Controller {
  static targets = ["criterion", "title", "label", "input", "out", "figure", "invalid", "only", "rest"]
  static values = { copy: Object }

  connect() {
    this.set("sas")
  }

  choose({ params }) {
    this.set(params.criterion)
  }

  // „AB" for a side, „ъгъл A" for an angle.
  named(part) {
    return part.angle ? `${this.copyValue.angle_word} ${part.name}` : part.name
  }

  set(criterion) {
    this.criterion = criterion
    CRITERIA[criterion].forEach((part, index) => {
      const input = this.inputTargets[index]
      input.min = part.min
      input.max = part.max
      input.step = part.step
      input.value = part.value
      this.labelTargets[index].textContent = this.named(part)
    })
    for (const button of this.criterionTargets) {
      button.setAttribute("aria-pressed", String(button.dataset.explainerCongruenceBuildCriterionParam === criterion))
    }
    this.render()
  }

  render() {
    const copy = this.copyValue
    const parts = CRITERIA[this.criterion]
    const values = this.inputTargets.map((input) => Number(input.value))
    const written = parts.map((part, index) => `${this.named(part)} = ${values[index]}${part.angle ? "°" : ""}`)
    const given = `${written[0]}, ${written[1]}${copy.and}${written[2]}`

    this.titleTarget.textContent = copy[`${this.criterion}_title`]
    parts.forEach((part, index) => { this.outTargets[index].textContent = `${values[index]}${part.angle ? "°" : ""}` })

    const triangle = solve(this.criterion, values)
    const failed = Boolean(triangle.error)
    this.invalidTarget.hidden = !failed
    this.onlyTarget.hidden = failed
    this.restTarget.hidden = failed

    if (failed) {
      let text = copy[`no_${triangle.error}`]
      for (const key of ["long", "x", "y", "sum", "alpha", "beta"]) text = text.replaceAll(`%{${key}}`, triangle[key] ?? "")
      this.invalidTarget.textContent = text
      this.figureTarget.replaceChildren(this.canvas(copy.figure_none))
      return
    }

    const names = parts.map((part) => part.name)
    const rest = [
      ...Object.entries(triangle.sides).map(([name, value]) => ({ name, value, angle: false })),
      ...Object.entries(triangle.angles).map(([name, value]) => ({ name, value, angle: true }))
    ].filter((part) => !names.includes(part.name)).map((part) => this.rounded(part))
    this.onlyTarget.textContent = copy.only.replaceAll("%{given}", given)
    this.restTarget.textContent = copy.rest.replaceAll("%{rest}", rest.join(", "))

    const svg = this.canvas(copy.figure.replaceAll("%{given}", given))
    const triangles = place(triangle.points)
    triangles.forEach((corners, index) => this.triangle(svg, corners, index === 1, names))
    for (const label of labels(triangles, names, values)) this.text(svg, label.at, label.text, label.kind === "vertex" ? "#312e81" : "#5048e5")
    this.figureTarget.replaceChildren(svg)
  }

  // „BC ≈ 4,7" — or „= 5" when the rounding changed nothing.
  rounded(part) {
    const shown = part.angle ? Math.round(part.value) : Math.round(part.value * 10) / 10
    const sign = Math.abs(shown - part.value) < 1e-6 ? "=" : "≈"
    return `${this.named(part)} ${sign} ${String(shown).replace(".", this.copyValue.point)}${part.angle ? "°" : ""}`
  }

  canvas(label) {
    const svg = this.node("svg", { viewBox: `0 0 ${WIDTH} ${HEIGHT}`, class: "w-full max-w-[420px]", role: "img" })
    svg.setAttribute("aria-label", label)
    return svg
  }

  // One triangle: the given sides heavy, the given angles marked with an arc.
  triangle(svg, corners, copyOf, names) {
    const vertex = { A: corners[0], B: corners[1], C: corners[2] }
    svg.append(this.node("polygon", { points: corners.map((corner) => corner.map((value) => value.toFixed(1)).join(",")).join(" "), fill: copyOf ? "#ececf4" : "#e2e4ff" }))

    for (const letter of ["A", "B", "C"]) {
      if (!names.includes(letter)) continue
      const at = vertex[letter]
      const [first, second] = ["A", "B", "C"].filter((other) => other !== letter).map((other) => unit([vertex[other][0] - at[0], vertex[other][1] - at[1]]))
      const sweep = first[0] * second[1] - first[1] * second[0] > 0 ? 1 : 0
      const [start, end] = [along(at, first, ARC), along(at, second, ARC)]
      svg.append(this.node("path", { d: `M ${at[0].toFixed(1)} ${at[1].toFixed(1)} L ${start[0].toFixed(1)} ${start[1].toFixed(1)} A ${ARC} ${ARC} 0 0 ${sweep} ${end[0].toFixed(1)} ${end[1].toFixed(1)} Z`, fill: "#a5aaff", stroke: "#5048e5", "stroke-width": 1.5 }))
    }

    for (const name of ["AB", "BC", "AC"]) {
      const [from, to] = [vertex[name[0]], vertex[name[1]]]
      const given = names.includes(name)
      svg.append(this.node("line", { x1: from[0].toFixed(1), y1: from[1].toFixed(1), x2: to[0].toFixed(1), y2: to[1].toFixed(1), stroke: given ? "#5048e5" : "#9a9ab0", "stroke-width": given ? 3.5 : 2, "stroke-linecap": "round" }))
    }
  }

  text(svg, [x, y], content, colour) {
    const text = this.node("text", { x: x.toFixed(1), y: (y + FONT / 3).toFixed(1), "text-anchor": "middle", "font-size": FONT, "font-weight": 900, fill: colour, stroke: "#f5f5fa", "stroke-width": 4, "stroke-linejoin": "round", "paint-order": "stroke" })
    text.textContent = content
    svg.append(text)
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
