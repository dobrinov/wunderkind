import { Controller } from "@hotwired/stimulus"

// Grid-shade widget: squared paper the student colours in — half of a shape to
// finish by symmetry, a region to mark off, a fraction of the grid to shade.
// {cells: ["r,c", ...]} is the answer state. Cells the question gives are drawn
// shaded and cannot be toggled.
export default class extends Controller {
  static targets = ["grid", "readout", "hidden"]
  static values = { rows: Number, cols: Number, given: Array, axis: Boolean }

  connect() {
    this.shaded = new Set()
    this.given = new Set(this.givenValue.map(String))
    this.render()
  }

  render() {
    const grid = document.createElement("div")
    grid.className = "grid w-full gap-0.5"
    grid.style.gridTemplateColumns = `repeat(${this.colsValue}, minmax(0, 1fr))`
    // 40px is the ideal cell; `w-full` shrinks the grid when the card is
    // narrower, which is the only thing a 20-column grid can do on a phone.
    grid.style.maxWidth = `${this.colsValue * 40}px`

    for (let r = 0; r < this.rowsValue; r++) {
      for (let c = 0; c < this.colsValue; c++) {
        const key = `${r},${c}`
        const fixed = this.given.has(key)
        const on = fixed || this.shaded.has(key)
        const cell = document.createElement("button")
        cell.type = "button"
        cell.disabled = fixed
        cell.setAttribute("aria-label", `${r + 1}, ${c + 1}`)
        cell.setAttribute("aria-pressed", on)
        cell.className = [
          "aspect-square rounded-[3px] border border-[var(--color-border)] transition-colors",
          fixed ? "bg-gray-400" : on ? "bg-[var(--color-accent)]" : "bg-[var(--color-surface)] hover:bg-[var(--color-accent-soft)]"
        ].join(" ")
        if (!fixed) cell.addEventListener("click", () => this.toggle(key))
        grid.append(cell)
      }
    }

    const wrapper = [grid]
    if (this.axisValue) {
      const axis = document.createElement("div")
      axis.className = "mx-auto h-0.5 w-full bg-accent-600"
      axis.style.maxWidth = `${this.colsValue * 40}px`
      wrapper.push(axis)
    }

    this.gridTarget.replaceChildren(...wrapper)
    if (this.hasReadoutTarget) this.readoutTarget.textContent = this.shaded.size || ""
    this.hiddenTarget.value = this.shaded.size ? JSON.stringify({ cells: [...this.shaded] }) : ""
  }

  toggle(key) {
    this.shaded.has(key) ? this.shaded.delete(key) : this.shaded.add(key)
    this.render()
  }
}
