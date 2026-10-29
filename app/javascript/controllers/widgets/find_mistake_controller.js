import { Controller } from "@hotwired/stimulus"
import { mathNode } from "../../lib/frac"

// Find-the-mistake widget: a worked solution, the problem on line 0 and one
// step per line after it. The student points at the line the mistake is made
// on — not one that merely carries it forward. {line: n} is the answer state.
// Real buttons, so a line can be chosen by tapping or from the keyboard, where
// the arrow keys move the choice up and down the solution.
export default class extends Controller {
  static targets = ["list", "hidden"]
  static values = { lines: Array, given: String }

  connect() {
    this.line = null
    this.render()
  }

  render() {
    this.buttons = []
    this.listTarget.replaceChildren(
      ...this.linesValue.map((text, index) => (index === 0 ? this.given(text) : this.step(text, index)))
    )
    this.hiddenTarget.value = this.line === null ? "" : JSON.stringify({ line: this.line })
  }

  given(text) {
    const row = document.createElement("div")
    row.className = "flex min-h-11 items-center gap-3 rounded-[12px] bg-ink-100 px-4 py-2"
    row.append(this.badge(this.givenValue, "text-micro uppercase tracking-[.05em] text-ink-500"), this.formula(text))
    return row
  }

  step(text, index) {
    const chosen = this.line === index
    const button = document.createElement("button")
    button.type = "button"
    button.setAttribute("aria-pressed", chosen)
    button.className = [
      "flex min-h-12 w-full items-center gap-3 rounded-[12px] border-2 px-4 py-2 text-left transition-colors",
      chosen
        ? "border-primary-500 bg-primary-50 shadow-[var(--edge-selected)]"
        : "border-[var(--color-border)] bg-[var(--color-surface)] shadow-[var(--edge-control)] hover:border-primary-300"
    ].join(" ")
    button.append(this.badge(index, "w-6 text-sm text-ink-500"), this.formula(text))
    button.addEventListener("click", () => this.choose(index))
    button.addEventListener("keydown", (event) => this.move(event, index))
    this.buttons[index] = button
    return button
  }

  badge(text, classes) {
    const badge = document.createElement("span")
    badge.className = `shrink-0 font-black ${classes}`
    badge.textContent = text
    return badge
  }

  // A line is maths, so a bare fraction in it is set stacked like the ones in
  // the question body; everything else stays as the problem file wrote it.
  formula(text) {
    const span = document.createElement("span")
    span.className = "text-xl font-bold text-ink-900"
    String(text).split(/(\s+)/).forEach((token) => span.append(mathNode(token)))
    return span
  }

  choose(index) {
    this.line = index
    this.render()
    this.buttons[index]?.focus()
  }

  move(event, index) {
    const delta = { ArrowDown: 1, ArrowUp: -1 }[event.key]
    if (!delta) return

    event.preventDefault()
    const next = Math.min(Math.max(index + delta, 1), this.linesValue.length - 1)
    this.choose(next)
  }
}
