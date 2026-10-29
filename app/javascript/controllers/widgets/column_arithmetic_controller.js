import { Controller } from "@hotwired/stimulus"

// Column arithmetic widget: written addition or subtraction, digit by digit.
// {result: "834", helpers: {"1": "1"}} is the answer state. Only the result row
// is graded; the small cells over each column (a carry, a borrowed digit) are
// the child's own working, kept with the answer so a parent can see it.
// Columns are counted from the right, 0 being the ones, because that is where
// a child starts and where the selection moves from.
export default class extends Controller {
  static targets = ["sheet", "keypad", "hidden"]
  static values = { operands: Array, op: String, labels: Object }

  connect() {
    const widest = Math.max(...this.operandsValue.map((operand) => operand.length))
    this.width = this.opValue === "+" ? widest + 1 : widest
    this.result = {}
    this.helpers = {}
    this.selected = { row: "result", col: 0 }
    this.onKey = (event) => this.key(event)
    this.element.addEventListener("keydown", this.onKey)
    this.renderKeypad()
    this.render()
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.onKey)
  }

  render() {
    const refocus = this.sheetTarget.contains(document.activeElement)
    const grid = document.createElement("div")
    grid.className = "grid items-center justify-items-center gap-x-1.5 gap-y-1"
    grid.style.gridTemplateColumns = `3rem repeat(${this.width}, 3rem)`

    // Helper row: the small cells for carrying or borrowing, named at its start.
    const caption = document.createElement("span")
    caption.className = "text-micro font-black leading-none text-reward-700"
    caption.textContent = this.labelsValue.helper ?? ""
    grid.append(caption)
    for (let col = this.width - 1; col >= 0; col--) grid.append(this.cell("helper", col))

    // Operands, right-aligned, with the sign on the last row.
    this.operandsValue.forEach((operand, index) => {
      const sign = document.createElement("span")
      sign.className = "text-3xl font-black text-ink-500"
      sign.textContent = index === this.operandsValue.length - 1 ? this.opValue : ""
      grid.append(sign)
      for (let col = this.width - 1; col >= 0; col--) {
        const digit = document.createElement("span")
        digit.className = "flex h-12 w-12 items-center justify-center text-3xl font-black text-ink-900"
        digit.textContent = operand[operand.length - 1 - col] ?? ""
        grid.append(digit)
      }
    })

    const rule = document.createElement("span")
    rule.className = "col-span-full h-1 w-full rounded-full bg-ink-900"
    grid.append(rule)

    grid.append(this.blank())
    for (let col = this.width - 1; col >= 0; col--) grid.append(this.cell("result", col))

    this.sheetTarget.replaceChildren(grid)
    if (refocus) this.selectedButton()?.focus()
    this.hiddenTarget.value = this.state()
  }

  cell(row, col) {
    const store = row === "result" ? this.result : this.helpers
    const selected = this.selected.row === row && this.selected.col === col
    const button = document.createElement("button")
    button.type = "button"
    button.dataset.row = row
    button.dataset.col = col
    button.textContent = store[col] ?? ""
    button.setAttribute("aria-pressed", selected)
    button.setAttribute("aria-label", this.cellLabel(row, col))
    button.className = [
      "flex items-center justify-center rounded-[12px] border-2 font-black motion-safe:transition-colors",
      row === "result" ? "h-14 w-12 text-3xl text-ink-900" : "h-11 w-11 text-base text-reward-700",
      selected
        ? "border-primary-600 bg-primary-50 shadow-[var(--edge-selected)]"
        : row === "result"
          ? "border-ink-300 bg-white shadow-[var(--edge-control)] hover:border-primary-300"
          : "border-dashed border-ink-300 bg-white hover:border-primary-300"
    ].join(" ")
    if (this.unused(row, col)) button.classList.add("invisible")
    button.addEventListener("click", () => this.select(row, col))
    return button
  }

  blank() {
    return document.createElement("span")
  }

  renderKeypad() {
    const keys = [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" ].map((digit) =>
      this.keyButton(digit, digit, () => this.write(digit))
    )
    keys.push(this.keyButton("⌫", this.labelsValue.erase, () => this.erase()))
    keys.push(this.keyButton("←", this.labelsValue.next, () => this.move(1)))
    this.keypadTarget.replaceChildren(...keys)
  }

  keyButton(text, label, action) {
    const button = document.createElement("button")
    button.type = "button"
    button.textContent = text
    button.setAttribute("aria-label", label)
    button.className = "h-12 rounded-[12px] border-2 border-ink-200 bg-white text-xl font-black text-ink-800 shadow-[var(--edge-control)] hover:border-primary-300 active:translate-y-0.5"
    button.addEventListener("click", action)
    return button
  }

  cellLabel(row, col) {
    const place = this.labelsValue.places?.[col] ?? String(col + 1)
    const template = row === "result" ? this.labelsValue.result_cell : this.labelsValue.helper_cell
    return template.replace("%{place}", place)
  }

  select(row, col) {
    this.selected = { row, col }
    this.render()
    this.selectedButton()?.focus()
  }

  selectedButton() {
    return this.sheetTarget.querySelector(`button[data-row="${this.selected.row}"][data-col="${this.selected.col}"]`)
  }

  // A result cell takes one digit and hands the selection to the next column
  // left, the way the sum is worked. A helper cell takes up to two ("14" over
  // a borrowed ones column) and keeps the selection.
  write(digit) {
    const { row, col } = this.selected
    if (row === "result") {
      this.result[col] = digit
      if (col < this.width - 1) this.selected = { row, col: col + 1 }
    } else {
      const current = this.helpers[col] ?? ""
      this.helpers[col] = current.length >= 2 ? digit : current + digit
    }
    this.render()
  }

  erase() {
    const { row, col } = this.selected
    delete (row === "result" ? this.result : this.helpers)[col]
    this.render()
  }

  move(delta) {
    let col = (this.selected.col + delta + this.width) % this.width
    if (this.unused(this.selected.row, col)) col = (col + delta + this.width) % this.width
    this.selected = { ...this.selected, col }
    this.render()
  }

  // Nothing is ever carried into the ones column, so in an addition that
  // helper cell is drawn invisible and the keys step over it.
  unused(row, col) {
    return row === "helper" && col === 0 && this.opValue === "+"
  }

  key(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return
    if (/^[0-9]$/.test(event.key)) {
      event.preventDefault()
      this.write(event.key)
    } else if (event.key === "Backspace" || event.key === "Delete") {
      event.preventDefault()
      this.erase()
    } else if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
      event.preventDefault()
      this.move(event.key === "ArrowLeft" ? 1 : -1)
    } else if (event.key === "ArrowUp" || event.key === "ArrowDown") {
      event.preventDefault()
      const row = event.key === "ArrowUp" ? "helper" : "result"
      this.selected = { row, col: this.unused(row, this.selected.col) ? 1 : this.selected.col }
      this.render()
    } else {
      return
    }
    this.selectedButton()?.focus()
  }

  // The digits written from the ones column leftwards, or "" while there is
  // nothing to submit or a gap sits between them — a gap is a cell not yet
  // done, not a zero.
  state() {
    const digits = []
    let col = 0
    while (this.result[col] !== undefined) digits.unshift(this.result[col++])
    const beyond = Object.keys(this.result).some((key) => Number(key) >= col)
    if (digits.length === 0 || beyond) return ""

    const helpers = Object.fromEntries(Object.entries(this.helpers).filter(([, value]) => value !== ""))
    return JSON.stringify({ result: digits.join(""), helpers })
  }
}
