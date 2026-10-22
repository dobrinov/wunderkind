import { Controller } from "@hotwired/stimulus"

// Grid-shade widget: squared paper the student colours in — half of a shape to
// finish by symmetry, a region to mark off, a fraction of the grid to shade.
// {cells: ["r,c", ...]} is the answer state. Cells the question gives are drawn
// shaded and cannot be toggled.
//
// A drag paints: the first cell decides whether the stroke colours or erases,
// and every cell the pointer crosses gets the same. One tap per cell made a
// 6 × 4 rectangle twenty-four taps, and children traced its edge instead — an
// outline, which is a perimeter and not the product the problem asks for. The
// grid takes `touch-action: none` so a finger paints rather than scrolls; the
// page still scrolls from anywhere outside it.
export default class extends Controller {
  static targets = ["grid", "readout", "hidden"]
  static values = { rows: Number, cols: Number, given: Array, axis: Boolean }

  connect() {
    this.shaded = new Set()
    this.given = new Set(this.givenValue.map(String))
    this.stroke = null
    this.build()
    this.update()
  }

  build() {
    const grid = document.createElement("div")
    grid.className = "grid w-full touch-none select-none gap-0.5"
    grid.style.gridTemplateColumns = `repeat(${this.colsValue}, minmax(0, 1fr))`
    // 40px is the ideal cell; `w-full` shrinks the grid when the card is
    // narrower, which is the only thing a 20-column grid can do on a phone.
    grid.style.maxWidth = `${this.colsValue * 40}px`

    this.cells = new Map()
    for (let r = 0; r < this.rowsValue; r++) {
      for (let c = 0; c < this.colsValue; c++) {
        const key = `${r},${c}`
        const cell = document.createElement("button")
        cell.type = "button"
        cell.dataset.key = key
        cell.disabled = this.given.has(key)
        cell.setAttribute("aria-label", `${r + 1}, ${c + 1}`)
        // A pointer paints through pointerdown; this is the keyboard's way in
        // (Space/Enter fire a click with detail 0), so a tap is not counted twice.
        cell.addEventListener("click", (event) => { if (event.detail === 0) this.toggle(key) })
        this.cells.set(key, cell)
        grid.append(cell)
      }
    }

    grid.addEventListener("pointerdown", (event) => this.start(event))
    grid.addEventListener("pointermove", (event) => this.move(event))
    grid.addEventListener("pointerup", () => this.end())
    grid.addEventListener("pointercancel", () => this.end())

    const wrapper = [grid]
    if (this.axisValue) {
      const axis = document.createElement("div")
      axis.className = "mx-auto h-0.5 w-full bg-accent-600"
      axis.style.maxWidth = `${this.colsValue * 40}px`
      wrapper.push(axis)
    }

    this.gridTarget.replaceChildren(...wrapper)
  }

  // `stroke` is null between strokes, undefined while a stroke that began on a
  // given cell has not yet crossed one it may paint, then true or false.
  start(event) {
    if (!event.target.closest("[data-key]")) return

    event.preventDefault()
    // Captured on the grid, so the stroke carries on when the pointer leaves
    // the cell it started on — moves are resolved by position, not by target.
    event.currentTarget.setPointerCapture(event.pointerId)
    this.stroke = undefined
    this.move(event)
  }

  move(event) {
    if (this.stroke === null) return

    const key = this.keyAt(event)
    if (!key) return

    if (this.stroke === undefined) this.stroke = !this.shaded.has(key)
    this.paint(key)
  }

  end() {
    this.stroke = null
  }

  keyAt(event) {
    const cell = document.elementFromPoint(event.clientX, event.clientY)?.closest("[data-key]")
    if (!cell || cell.disabled || !this.gridTarget.contains(cell)) return null
    return cell.dataset.key
  }

  paint(key) {
    if (this.shaded.has(key) === this.stroke) return

    this.stroke ? this.shaded.add(key) : this.shaded.delete(key)
    this.update()
  }

  toggle(key) {
    this.shaded.has(key) ? this.shaded.delete(key) : this.shaded.add(key)
    this.update()
  }

  update() {
    for (const [key, cell] of this.cells) {
      const fixed = this.given.has(key)
      const on = fixed || this.shaded.has(key)
      cell.setAttribute("aria-pressed", on)
      cell.className = [
        "aspect-square rounded-[3px] border border-[var(--color-border)] transition-colors",
        fixed ? "bg-gray-400" : on ? "bg-[var(--color-accent)]" : "bg-[var(--color-surface)] hover:bg-[var(--color-accent-soft)]"
      ].join(" ")
    }

    if (this.hasReadoutTarget) this.readoutTarget.textContent = this.shaded.size || ""
    this.hiddenTarget.value = this.shaded.size ? JSON.stringify({ cells: [...this.shaded] }) : ""
  }
}
