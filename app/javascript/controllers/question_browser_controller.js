import { Controller } from "@hotwired/stimulus"

// The admin question browser. A facet changing submits the search form (the
// facets name it with `form=`), a row chosen is marked at once while its pane
// loads, and the keyboard walks the list: ↑/↓ choose the previous or next
// row, E opens the chosen one in the editor. Keys typed into a field are the
// field's, never the list's.
export default class extends Controller {
  static targets = ["form", "row", "apply"]

  connect() {
    if (this.hasApplyTarget) this.applyTarget.hidden = true
    this.keydown = this.keydown.bind(this)
    document.addEventListener("keydown", this.keydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.keydown)
  }

  submit(event) {
    // A row's own change events never reach here, but the search box's would
    // on blur — typing is submitted with Enter, not by leaving the field.
    if (event?.target?.type === "search") return
    this.formTarget.requestSubmit()
  }

  select(event) {
    this.mark(event.currentTarget)
  }

  mark(row) {
    this.rowTargets.forEach((each) => {
      if (each === row) each.setAttribute("aria-current", "true")
      else each.removeAttribute("aria-current")
    })
  }

  keydown(event) {
    if (event.defaultPrevented || event.metaKey || event.ctrlKey || event.altKey) return
    const target = event.target
    if (target.closest("input, textarea, select, [contenteditable]") || target.isContentEditable) return

    const rows = this.rowTargets
    if (rows.length === 0) return
    const current = rows.findIndex((row) => row.getAttribute("aria-current") === "true")

    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const step = event.key === "ArrowDown" ? 1 : -1
      const next = rows[Math.min(Math.max(current + step, 0), rows.length - 1)]
      if (next && next !== rows[current]) {
        next.click()
        next.scrollIntoView({ block: "nearest" })
      }
    } else if (event.key === "e" || event.key === "E") {
      const row = rows[current]
      if (!row) return
      event.preventDefault()
      window.Turbo ? window.Turbo.visit(row.dataset.editUrl) : (window.location.href = row.dataset.editUrl)
    }
  }
}
