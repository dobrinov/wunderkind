import { Controller } from "@hotwired/stimulus"
import { setMath } from "../../lib/frac"

// Fraction bars widget: the student shades parts of a whole;
// {shaded: count} is the answer state.
export default class extends Controller {
  static targets = ["bar", "hidden", "readout"]
  static values = { segments: Number }

  connect() {
    this.shaded = new Set()
    this.render()
  }

  render() {
    this.barTarget.replaceChildren(
      ...Array.from({ length: this.segmentsValue }, (_, index) => {
        const segment = document.createElement("button")
        segment.type = "button"
        segment.setAttribute("aria-pressed", this.shaded.has(index))
        segment.className = [
          "h-16 flex-1 border-2 border-[var(--color-border)] first:rounded-l-[10px] last:rounded-r-[10px] transition-colors",
          this.shaded.has(index) ? "bg-[var(--color-accent)]" : "bg-[var(--color-surface)] hover:bg-[var(--color-accent-soft)]"
        ].join(" ")
        segment.addEventListener("click", () => this.toggle(index))
        return segment
      })
    )
    this.hiddenTarget.value = JSON.stringify({ shaded: this.shaded.size })
    // A stacked fraction, so the counter matches the notation the question
    // above it is set in.
    if (this.hasReadoutTarget) {
      setMath(this.readoutTarget, `${this.shaded.size}/${this.segmentsValue}`)
    }
  }

  toggle(index) {
    this.shaded.has(index) ? this.shaded.delete(index) : this.shaded.add(index)
    this.render()
  }
}
