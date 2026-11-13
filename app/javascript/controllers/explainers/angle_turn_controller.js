import { Controller } from "@hotwired/stimulus"

// „Видове ъгли": an angle as a turn. One arm lies on a straight line, the
// other turns about the vertex from 0° to 180°; the angle is named for where
// it stands against 90° and 180°, and the grey angle left over on the line —
// the съседен ъгъл — is always 180° minus it. A right angle is marked with
// the small square a textbook uses, on whichever side it falls.
const SVG = "http://www.w3.org/2000/svg"
const CX = 210, CY = 196, ARM = 150, ARC = 46, SQUARE = 22
// Where a size is written: inside its angle, this far from the vertex — or,
// for an angle too narrow to hold it, under the line on the angle's side.
const LABEL = 84, NARROW = 30, FONT = 18

// The centre of the label for the angle between two directions.
export function labelAt(from, to) {
  if (to - from < NARROW) return [from === 0 ? CX + 112 : CX - 112, CY + 26]
  const radians = (((from + to) / 2) * Math.PI) / 180
  return [CX + LABEL * Math.cos(radians), CY - LABEL * Math.sin(radians)]
}

const kindOf = (degrees) => degrees === 0 ? "zero" : degrees < 90 ? "acute" : degrees === 90 ? "right" : degrees < 180 ? "obtuse" : "straight"

export default class extends Controller {
  static targets = ["angle", "angleOut", "figure", "name", "adjacent", "note"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const angle = Number(this.angleTarget.value)
    const adjacent = 180 - angle
    const kind = kindOf(angle)
    const fill = (text, kindName) => text.replaceAll("%{angle}", angle).replaceAll("%{adjacent}", adjacent).replaceAll("%{kind}", kindName)

    this.angleOutTarget.textContent = `${angle}°`
    this.nameTarget.textContent = kind === "zero" ? copy.name_zero : fill(copy.name, copy[`kind_${kind}`])
    this.adjacentTarget.textContent = angle === 0 ? copy.adjacent_none : adjacent === 0 ? copy.adjacent_gone : fill(copy.adjacent, copy[`kind_${kindOf(adjacent)}`])
    this.noteTarget.textContent = copy[`note_${kind}`]
    this.figureTarget.replaceChildren(this.drawing(angle, adjacent, fill(copy.figure, "")))
  }

  drawing(angle, adjacent, label) {
    const svg = this.node("svg", { viewBox: "0 0 420 250", class: "w-full max-w-[520px]", role: "img" })
    svg.setAttribute("aria-label", label)

    // The two angles first, so the arms are drawn over their marks.
    if (angle > 0 && adjacent > 0) this.mark(svg, angle, 180, "#ececf4", "#9a9ab0", ARC - 12)
    if (angle > 0) this.mark(svg, 0, angle, "#e2e4ff", "#5048e5", ARC)

    // The straight line, and the arm that turns.
    svg.append(this.node("line", { x1: 40, y1: CY, x2: 380, y2: CY, stroke: "#9a9ab0", "stroke-width": 4, "stroke-linecap": "round" }))
    svg.append(this.node("line", { x1: CX, y1: CY, x2: CX + ARM, y2: CY, stroke: "#312e81", "stroke-width": 4, "stroke-linecap": "round" }))
    const [x, y] = this.point(angle, ARM)
    svg.append(this.node("line", { x1: CX, y1: CY, x2: x, y2: y, stroke: "#5048e5", "stroke-width": 5, "stroke-linecap": "round" }))
    svg.append(this.node("circle", { cx: CX, cy: CY, r: 5, fill: "#312e81" }))

    // Each size inside the angle it measures. At 0° there is one straight
    // angle and nothing next to it yet.
    if (angle > 0) this.text(svg, labelAt(0, angle), `${angle}°`, "#5048e5")
    if (angle > 0 && adjacent > 0) this.text(svg, labelAt(angle, 180), `${adjacent}°`, "#50506b")
    return svg
  }

  // The mark of the angle between two directions: a filled sector with its
  // arc, or — at exactly 90° — the small square.
  mark(svg, from, to, fill, stroke, radius) {
    if (to - from === 90) {
      const [ax, ay] = this.point(from, SQUARE)
      const [bx, by] = this.point(to, SQUARE)
      const [cx, cy] = [ax + bx - CX, ay + by - CY]
      svg.append(this.node("path", { d: `M ${CX} ${CY} L ${ax} ${ay} L ${cx} ${cy} L ${bx} ${by} Z`, fill, stroke, "stroke-width": 2.5, "stroke-linejoin": "round" }))
      return
    }
    const [ax, ay] = this.point(from, radius)
    const [bx, by] = this.point(to, radius)
    svg.append(this.node("path", { d: `M ${CX} ${CY} L ${ax} ${ay} A ${radius} ${radius} 0 0 0 ${bx} ${by} Z`, fill }))
    svg.append(this.node("path", { d: `M ${ax} ${ay} A ${radius} ${radius} 0 0 0 ${bx} ${by}`, fill: "none", stroke, "stroke-width": 3, "stroke-linecap": "round" }))
  }

  // The point `length` from the vertex in the direction `degrees`, measured
  // anticlockwise from the fixed arm.
  point(degrees, length) {
    const radians = (degrees * Math.PI) / 180
    return [Math.round((CX + length * Math.cos(radians)) * 100) / 100, Math.round((CY - length * Math.sin(radians)) * 100) / 100]
  }

  text(svg, [x, y], content, colour) {
    const text = this.node("text", { x: x.toFixed(1), y: (y + FONT / 3).toFixed(1), "text-anchor": "middle", "font-size": FONT, "font-weight": 900, fill: colour, stroke: "#f5f5fa", "stroke-width": 5, "stroke-linejoin": "round", "paint-order": "stroke" })
    text.textContent = content
    svg.append(text)
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
