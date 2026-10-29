import { Controller } from "@hotwired/stimulus"

// The first-run tour on „Днес": three steps, each pointing at one thing on the
// page — today's session, the streak-and-level chip, the menu. A child who
// signs up has just finished eight placement problems and lands on a page
// they have never seen; three sentences about where things are is the whole
// of the introduction, and everything else arrives later, one feature at a
// time (FeatureVisibility).
//
// Steps are found by `data-tour="<name>"` on the page, so the markup says what
// is being pointed at; a step whose element is not visible at this width (the
// header nav on a phone, the tab bar on a tablet) falls through to the next
// candidate in `targets`. Finishing and skipping are the same answer to the
// server — PATCH /tour — because the tour is shown once either way.
export default class extends Controller {
  static targets = ["bubble", "title", "body", "count", "next"]
  static values = { url: String, steps: Array, done: String, next: String }

  connect() {
    this.index = 0
    this.show()
    this.reposition = () => this.place()
    window.addEventListener("resize", this.reposition)
  }

  disconnect() {
    window.removeEventListener("resize", this.reposition)
    this.clearHighlight()
  }

  next() {
    if (this.index >= this.stepsValue.length - 1) return this.finish()
    this.index += 1
    this.show()
  }

  finish() {
    this.clearHighlight()
    this.element.remove()
    const token = document.querySelector("meta[name=csrf-token]")?.content
    fetch(this.urlValue, { method: "PATCH", headers: { "X-CSRF-Token": token, "Accept": "application/json" }, credentials: "same-origin" })
  }

  show() {
    const step = this.stepsValue[this.index]
    this.titleTarget.textContent = step.title
    this.bodyTarget.textContent = step.body
    this.countTarget.textContent = `${this.index + 1} / ${this.stepsValue.length}`
    this.nextTarget.textContent = this.index === this.stepsValue.length - 1 ? this.doneValue : this.nextValue

    this.clearHighlight()
    this.target = step.targets.map((name) => document.querySelector(`[data-tour="${name}"]`))
      .find((element) => element && element.getClientRects().length > 0 && getComputedStyle(element).visibility !== "hidden")
    if (this.target) {
      this.target.classList.add("tour-highlight")
      // The chip lives in the sticky header, which is a stacking context of
      // its own: lifted only inside it, its dimming stopped at the header and
      // the tab bar stayed bright. Lift the sticky container with it.
      const container = this.target.parentElement?.closest("header, .tabbar")
      if (container) container.classList.add("tour-lift")
      this.target.scrollIntoView({ block: "center", behavior: "smooth" })
    }
    this.place()
    this.nextTarget.focus()
  }

  // Below the highlighted element when there is room, above it otherwise; the
  // bubble spans the screen on a phone and sits by the element on a tablet.
  place() {
    const bubble = this.bubbleTarget
    if (!this.target) {
      bubble.style.top = "50%"
      bubble.style.transform = "translateY(-50%)"
      return
    }
    const rect = this.target.getBoundingClientRect()
    const gap = 14
    const below = rect.bottom + gap + bubble.offsetHeight < window.innerHeight
    bubble.style.transform = ""
    bubble.style.top = below ? `${rect.bottom + gap}px` : `${Math.max(gap, rect.top - gap - bubble.offsetHeight)}px`
  }

  clearHighlight() {
    document.querySelectorAll(".tour-highlight").forEach((element) => element.classList.remove("tour-highlight"))
    document.querySelectorAll(".tour-lift").forEach((element) => element.classList.remove("tour-lift"))
  }
}
