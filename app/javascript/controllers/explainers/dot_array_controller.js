import { Controller } from "@hotwired/stimulus"

// „Умножение и деление": dots in rows and columns, one slider for each. The
// rows are the equal groups — shaded alternately so each can be told from
// the next — and the same picture is read as a repeated sum, as the two
// multiplications and as the two divisions that undo them. The array grows
// from the top left corner at a fixed spacing, so a bigger product is a
// visibly bigger patch of dots; ten by ten fills the box.
const SVG = "http://www.w3.org/2000/svg"
const SIZE = 290, FIRST = 23, GAP = 27, RADIUS = 10

export default class extends Controller {
  static targets = ["rows", "cols", "rowsOut", "colsOut", "figure", "groups", "sum", "times", "turned", "divideByCols", "divideByRows", "note"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  // Rows become columns: the same dots, counted the other way.
  turn() {
    const rows = this.rowsTarget.value
    this.rowsTarget.value = this.colsTarget.value
    this.colsTarget.value = rows
    this.render()
  }

  render() {
    const copy = this.copyValue
    const rows = Number(this.rowsTarget.value)
    const cols = Number(this.colsTarget.value)
    const product = rows * cols
    const fill = (text) => text.replaceAll("%{rows}", rows).replaceAll("%{cols}", cols).replaceAll("%{product}", product)

    this.rowsOutTarget.textContent = rows
    this.colsOutTarget.textContent = cols
    this.groupsTarget.textContent = fill(rows === 1 ? copy.groups_one : copy.groups_many)
    // One row is not a sum; the line would read „6 = 6".
    this.sumTarget.hidden = rows === 1
    this.sumTarget.textContent = `${Array(rows).fill(cols).join(" + ")} = ${product}`
    this.timesTarget.textContent = fill(copy.times)
    this.turnedTarget.textContent = fill(copy.turned)
    this.divideByColsTarget.textContent = fill(copy.divide_by_cols)
    this.divideByRowsTarget.textContent = fill(copy.divide_by_rows)
    this.noteTarget.textContent = fill(copy.note)
    this.figureTarget.replaceChildren(this.dots(rows, cols, fill(copy.figure)))
  }

  dots(rows, cols, label) {
    const svg = this.node("svg", { viewBox: `0 0 ${SIZE} ${SIZE}`, class: "w-full max-w-[300px]", role: "img" })
    svg.setAttribute("aria-label", label)
    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        svg.append(this.node("circle", { cx: FIRST + col * GAP, cy: FIRST + row * GAP, r: RADIUS, fill: row % 2 === 0 ? "#5048e5" : "#a5aaff" }))
      }
    }
    return svg
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
