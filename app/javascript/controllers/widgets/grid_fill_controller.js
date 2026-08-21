import { Controller } from "@hotwired/stimulus"

// Grid-fill widget: a table with some cells given and some to work out — a magic
// square, a times table with holes, a table of values for a function.
// {cells: {"r,c": text}} is the answer state; only the blank cells are editable.
export default class extends Controller {
  static targets = ["table", "hidden"]
  static values = { rows: Array, columnHeaders: Array, rowHeaders: Array }

  connect() {
    this.values = {}
    this.render()
  }

  render() {
    const table = document.createElement("table")
    table.className = "mx-auto border-collapse"
    // A 10-column times table at 64px a cell is 640px wide and spends the
    // whole question sideways-scrolling, so the wide ones get smaller cells.
    const columns = Math.max(...this.rowsValue.map((row) => row.length)) +
      (this.rowHeadersValue.length ? 1 : 0)
    this.cellSize = columns >= 9 ? "size-10 text-base" : columns >= 7 ? "size-12 text-lg" : "size-16 text-xl"
    this.headerPad = columns >= 7 ? "px-1 py-1" : "px-3 py-1.5"

    if (this.columnHeadersValue.length) {
      const head = table.createTHead().insertRow()
      if (this.rowHeadersValue.length) head.append(this.cell("th", ""))
      this.columnHeadersValue.forEach((header) => head.append(this.cell("th", header)))
    }

    const body = table.createTBody()
    this.rowsValue.forEach((row, r) => {
      const tr = body.insertRow()
      if (this.rowHeadersValue.length) tr.append(this.cell("th", this.rowHeadersValue[r] ?? ""))

      row.forEach((value, c) => {
        const td = document.createElement("td")
        td.className = "border-2 border-[var(--color-border)] p-0"
        if (value === null || value === "") {
          const input = document.createElement("input")
          input.type = "text"
          input.inputMode = "decimal"
          input.autocomplete = "off"
          input.setAttribute("aria-label", `${r + 1}, ${c + 1}`)
          // min-w-0 to beat the `min-w-32` every text input carries: without it
          // a cell is 128px wide however small size-* asks for, so the columns
          // with a blank in them come out twice the width of the given ones.
          input.className = `${this.cellSize} min-w-0 bg-primary-50/60 text-center font-black outline-0 focus:bg-white focus:ring-2 focus:ring-primary-500`
          input.addEventListener("input", (event) => this.update(`${r},${c}`, event.target.value))
          td.append(input)
        } else {
          td.className += " bg-[var(--color-surface)]"
          const span = document.createElement("span")
          span.className = `grid ${this.cellSize} place-items-center font-bold text-gray-700`
          span.textContent = value
          td.append(span)
        }
        tr.append(td)
      })
    })

    this.tableTarget.replaceChildren(table)
    this.blanks = this.rowsValue.flatMap((row, r) =>
      row.map((value, c) => (value === null || value === "" ? `${r},${c}` : null)).filter(Boolean)
    )
    this.sync()
  }

  cell(tag, text) {
    const element = document.createElement(tag)
    element.className = `${this.headerPad} text-sm font-black text-gray-500`
    element.textContent = text
    return element
  }

  update(key, value) {
    this.values[key] = value
    this.sync()
  }

  sync() {
    const complete = this.blanks.every((key) => (this.values[key] ?? "").trim() !== "")
    this.hiddenTarget.value = complete ? JSON.stringify({ cells: this.values }) : ""
  }
}
