import { Controller } from "@hotwired/stimulus"

// The multiplication table on its public page (times_tables/show). The table
// is already there as HTML; this lights the row and column of the cell under
// the pointer — or the focused one, or on a touch screen the tapped one, where
// there is no hover — and writes out its product and the two divisions that
// come from it. „Скрий отговорите" turns every cell into a „?" that only a
// tap turns back: pointing at a hidden cell moves the cross and asks the
// question, and gives nothing away.
export default class extends Controller {
  static targets = ["cell", "row", "column", "product", "division", "tip", "hide"]
  static values = { copy: Object }

  connect() {
    this.revealed = new Set()
    this.select(7, 8)
  }

  hover({ currentTarget }) {
    this.select(Number(currentTarget.dataset.row), Number(currentTarget.dataset.column))
  }

  pick({ currentTarget }) {
    this.revealed.add(currentTarget)
    this.select(Number(currentTarget.dataset.row), Number(currentTarget.dataset.column))
  }

  toggleHidden() {
    this.revealed.clear()
    this.render()
  }

  select(row, column) {
    this.row = row
    this.column = column
    this.render()
  }

  render() {
    const hidden = this.hideTarget.checked
    const { row, column } = this
    let known = true

    for (const cell of this.cellTargets) {
      const r = Number(cell.dataset.row)
      const c = Number(cell.dataset.column)
      const on = r === row && c === column
      cell.classList.toggle("is-on", on)
      cell.classList.toggle("is-lane", !on && (r === row || c === column))
      const shown = !(hidden && !this.revealed.has(cell))
      if (on) known = shown
      cell.textContent = shown ? r * c : "?"
      // The spoken name carries the product only while the cell shows it.
      cell.setAttribute("aria-label", (shown ? this.copyValue.cell : this.copyValue.cell_hidden)
        .replaceAll("%{a}", r).replaceAll("%{b}", c).replaceAll("%{product}", r * c))
    }
    for (const head of this.rowTargets) head.classList.toggle("is-on", Number(head.dataset.number) === row)
    for (const head of this.columnTargets) head.classList.toggle("is-on", Number(head.dataset.number) === column)

    const product = row * column
    this.productTarget.textContent = `${row} × ${column} = ${known ? product : "?"}`
    this.divisionTarget.textContent = !known ? "" : row === column
      ? `${product} : ${row} = ${row}`
      : `${product} : ${column} = ${row}\n${product} : ${row} = ${column}`
    this.tipTarget.textContent = known ? this.tip(row, column, product) : ""
  }

  // One remark about the picked product: the rule for its row where there is
  // one, otherwise that the table reads the same both ways.
  tip(row, column, product) {
    const copy = this.copyValue
    // replaceAll: a square's line names its number twice („5 × 5"), and
    // replace only fills the first.
    const fill = (text) => text.replaceAll("%{a}", row).replaceAll("%{b}", column).replaceAll("%{product}", product)
      .replaceAll("%{digits}", String(product).split("").join(" + "))

    if (row === column) return fill(copy.square)
    if (row === 10 || column === 10) return fill(copy.ten)
    if (row === 9 || column === 9) return fill(copy.nine)
    if (row === 5 || column === 5) return fill(copy.five)
    return fill(copy.swap)
  }
}
