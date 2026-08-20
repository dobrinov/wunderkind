import { Controller } from "@hotwired/stimulus"

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
          "h-16 flex-1 border-2 border-[var(--color-border)] first:rounded-l-lg last:rounded-r-lg transition-colors",
          this.shaded.has(index) ? "bg-[var(--color-accent)]" : "bg-[var(--color-surface)] hover:bg-[var(--color-accent-soft)]"
        ].join(" ")
        segment.addEventListener("click", () => this.toggle(index))
        return segment
      })
    )
    this.hiddenTarget.value = JSON.stringify({ shaded: this.shaded.size })
    if (this.hasReadoutTarget) {
      this.readoutTarget.textContent = `${this.shaded.size}/${this.segmentsValue}`
    }
  }

  toggle(index) {
    this.shaded.has(index) ? this.shaded.delete(index) : this.shaded.add(index)
    this.render()
  }
}
