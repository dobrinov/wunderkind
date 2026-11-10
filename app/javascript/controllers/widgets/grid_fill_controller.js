import { Controller } from "@hotwired/stimulus"

// Grid-fill widget: a table with some cells given and some to work out — a magic
// square, a times table with holes, a table of values for a function.
// {cells: {"r,c": text}} is the answer state; only the blank cells are editable.
export default class extends Controller {
  static targets = ["table", "hidden"]
  static values = { rows: Array, columnHeaders: Array, rowHeaders: Array, cellLabel: String, layout: String }

  connect() {
    this.values = {}
    this.render()
  }

  // What a screen reader calls a cell: the table's own headers where it has
  // them („7, 8" in a times table), „ред 2, колона 3" where it has none —
  // it used to be the bare coordinates, „2, 3".
  cellName(r, c) {
    const row = this.rowHeadersValue[r]
    const column = this.columnHeadersValue[c]
    if (row != null && row !== "" && column != null && column !== "") return `${row}, ${column}`
    return this.cellLabelValue.replace("%row", r + 1).replace("%column", c + 1)
  }

  render() {
    if (this.layoutValue === "pyramid") return this.renderPyramid()

    const table = document.createElement("table")
    // min-w-0 to beat the `min-w-full` every table in the app carries for the
    // sake of the admin lists: without it the columns share out the card's
    // width and the cells are not square.
    table.className = "mx-auto min-w-0 border-collapse"
    // A 10-column times table at 64px a cell is 640px wide and spends the whole
    // question sideways-scrolling, so the wide ones get smaller cells — a step
    // smaller again on a phone, down to 40px, which is as small as a box worth
    // tapping gets.
    const columns = Math.max(0, ...this.rowsValue.map((row) => row.length)) +
      (this.rowHeadersValue.length ? 1 : 0)
    this.cellSize =
      columns >= 9 ? "size-10 text-base" :
      columns >= 7 ? "size-10 text-base sm:size-12 sm:text-lg" :
      columns >= 5 ? "size-12 text-lg sm:size-16 sm:text-xl" : "size-16 text-xl"
    this.headerPad = columns >= 7 ? "px-1 py-1" : columns >= 5 ? "px-2 py-1" : "px-3 py-1.5"

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
        // "" is a cell that is not part of the puzzle (the empty corners of an
        // addition pyramid), not a blank: only null is asked for, and only
        // null is in the stored solution.
        if (value === "") {
          tr.append(td)
          return
        }
        td.className = "border-2 border-[var(--color-border)] p-0"
        if (value === null) {
          const input = document.createElement("input")
          input.type = "text"
          // The ordinary keyboard, not the decimal keypad: an iPhone's has digits
          // and a comma and nothing else, and several hundred of these blanks are
          // a negative number or a fraction, which could only be skipped there.
          input.inputMode = "text"
          input.autocomplete = "off"
          input.setAttribute("aria-label", this.cellName(r, c))
          // min-w-0 to beat the `min-w-32` every text input carries: without it
          // a cell is 128px wide however small size-* asks for, so the columns
          // with a blank in them come out twice the width of the given ones.
          input.className = `${this.cellSize} min-w-0 bg-primary-50/60 text-center font-black outline-0 focus:bg-white focus:ring-2 focus:ring-primary-500`
          input.addEventListener("input", (event) => this.update(`${r},${c}`, event.target.value))
          td.append(input)
        } else {
          td.className += " bg-[var(--color-surface)]"
          const span = document.createElement("span")
          span.className = `grid ${this.cellSize} place-items-center font-bold text-ink-700`
          span.textContent = value
          td.append(span)
        }
        tr.append(td)
      })
    })

    // mx-auto centres a table that fits, and collapses to zero on one that
    // does not, so a table too wide for the card opens at its first column and
    // scrolls right rather than half-way through itself.
    this.tableTarget.replaceChildren(table)
    this.blanks = this.rowsValue.flatMap((row, r) =>
      row.map((value, c) => (value === null ? `${r},${c}` : null)).filter(Boolean)
    )
    this.sync()
  }

  // An addition pyramid: the rows come base first, and are drawn the other
  // way up, centred, so every cell sits between the two below it that it is
  // the sum of. As a left-aligned table the base was on top and each cell sat
  // straight over one other cell — a student reported they could not tell
  // which two made the third. "" cells are the padding the table needed; here
  // they are simply left out, so the keys ("r,c") stay what the solution uses.
  renderPyramid() {
    this.cellSize = "size-14 text-xl sm:size-16"
    const pyramid = document.createElement("div")
    pyramid.className = "mx-auto flex w-max flex-col items-center gap-1.5"
    const height = this.rowsValue.length

    this.rowsValue.forEach((row, r) => {
      const line = document.createElement("div")
      line.className = "flex gap-1.5"
      row.forEach((value, c) => {
        if (value === "") return

        const box = document.createElement("div")
        box.className = "overflow-hidden rounded-lg border-2 border-[var(--color-border)]"
        if (value === null) {
          box.append(this.input(r, c, this.cellLabelValue.replace("%row", height - r).replace("%column", c + 1)))
        } else {
          box.className += " bg-[var(--color-surface)]"
          const span = document.createElement("span")
          span.className = `grid ${this.cellSize} place-items-center font-bold text-ink-700`
          span.textContent = value
          box.append(span)
        }
        line.append(box)
      })
      pyramid.prepend(line)
    })

    this.tableTarget.replaceChildren(pyramid)
    this.blanks = this.rowsValue.flatMap((row, r) =>
      row.map((value, c) => (value === null ? `${r},${c}` : null)).filter(Boolean)
    )
    this.sync()
  }

  input(r, c, label) {
    const input = document.createElement("input")
    input.type = "text"
    input.inputMode = "text"
    input.autocomplete = "off"
    input.setAttribute("aria-label", label)
    input.className = `block ${this.cellSize} min-w-0 bg-primary-50/60 text-center font-black outline-0 focus:bg-white focus:ring-2 focus:ring-inset focus:ring-primary-500`
    input.addEventListener("input", (event) => this.update(`${r},${c}`, event.target.value))
    return input
  }

  cell(tag, text) {
    const element = document.createElement(tag)
    element.className = `${this.headerPad} text-sm font-black text-ink-500`
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
