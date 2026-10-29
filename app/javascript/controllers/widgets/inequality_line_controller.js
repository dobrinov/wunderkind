import { Controller } from "@hotwired/stimulus"

// Inequality on a number line: the student marks where the boundary is,
// whether it belongs (a filled or an open dot) and which way the ray runs.
// {edge, closed, direction} is the answer state, and it is only written once
// all three have been chosen — nothing starts selected, so a guess at the
// kind of dot or the direction is never free.
export default class extends Controller {
  static targets = ["line", "kind", "direction", "readout", "hidden"]
  static values = {
    min: Number,
    max: Number,
    step: { type: Number, default: 1 },
    pointLabel: String
  }

  connect() {
    this.edge = null
    this.closed = null
    this.direction = null
    this.ticks = this.tickValues()
    this.renderLine()
    this.render()
  }

  tickValues() {
    const count = Math.round((this.maxValue - this.minValue) / this.stepValue)
    return Array.from({ length: count + 1 }, (_, i) => this.round(this.minValue + i * this.stepValue))
  }

  // The ticks are buttons, built once; the dot and the ray are redrawn on top.
  renderLine() {
    const axis = document.createElement("div")
    axis.className = "absolute inset-x-0 top-11 h-1 rounded-full bg-ink-300"

    this.ray = document.createElement("div")
    this.ray.className = "absolute top-10 h-3 rounded-full bg-primary-300 transition-all motion-reduce:transition-none"
    this.ray.hidden = true

    this.arrow = document.createElement("div")
    this.arrow.className = "absolute top-[34px] size-0 border-y-[12px] border-y-transparent"
    this.arrow.hidden = true

    this.buttons = this.ticks.map((value) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "group absolute top-0 flex h-full -translate-x-1/2 flex-col items-center rounded-[10px] focus-visible:outline-3 focus-visible:outline-primary-300"
      button.style.left = `${this.position(value)}%`
      // One tick-spacing wide at most, so neighbouring buttons never overlap:
      // a 44px button on a line of 13 ticks at phone width covered half the
      // next one, and a tap on a tick picked the tick to its right.
      button.style.width = `min(2.75rem, ${100 / (this.ticks.length - 1)}%)`
      button.setAttribute("aria-label", this.pointLabelValue.replace("%{value}", this.format(value)))
      button.setAttribute("aria-pressed", "false")
      button.tabIndex = -1
      button.addEventListener("click", () => this.pickEdge(value))

      const mark = document.createElement("span")
      mark.className = "mt-[34px] h-6 w-[3px] rounded-full bg-ink-400 group-hover:bg-primary-600"
      button.append(mark)

      if (this.labelled(value)) {
        const label = document.createElement("span")
        label.className = "mt-2 text-ui font-black text-ink-700"
        label.textContent = this.format(value)
        button.append(label)
      }
      return button
    })
    this.buttons[Math.floor(this.buttons.length / 2)].tabIndex = 0

    this.dot = document.createElement("span")
    this.dot.className = "pointer-events-none absolute top-[33px] size-7 -translate-x-1/2 rounded-full border-[5px] border-primary-600 transition-[left] motion-reduce:transition-none"
    this.dot.hidden = true

    // The bar sits on a padded inner track so the end ticks stay tappable.
    const track = document.createElement("div")
    track.className = "absolute inset-y-0 left-6 right-6"
    track.append(axis, this.ray, this.arrow, ...this.buttons, this.dot)
    this.lineTarget.replaceChildren(track)
  }

  // On a line in halves only the whole numbers are numbered; thirteen labels
  // like "−2,5" side by side are wider than a phone.
  labelled(value) {
    return this.stepValue >= 1 || Number.isInteger(value)
  }

  render() {
    const hasEdge = this.edge !== null

    this.buttons.forEach((button, i) => button.setAttribute("aria-pressed", String(this.ticks[i] === this.edge)))
    this.kindTargets.forEach((button) => button.setAttribute("aria-pressed", String(this.closed !== null && button.dataset.value === String(this.closed))))
    this.directionTargets.forEach((button) => button.setAttribute("aria-pressed", String(button.dataset.value === this.direction)))

    this.dot.hidden = !hasEdge
    if (hasEdge) {
      this.dot.style.left = `${this.position(this.edge)}%`
      // Until the kind of dot is chosen it is drawn dashed: a boundary, but
      // neither answer to "does it belong".
      this.dot.classList.toggle("bg-primary-600", this.closed === true)
      this.dot.classList.toggle("bg-white", this.closed !== true)
      this.dot.classList.toggle("border-dashed", this.closed === null)
    }

    const showRay = hasEdge && this.direction !== null
    this.ray.hidden = this.arrow.hidden = !showRay
    if (showRay) {
      const at = this.position(this.edge)
      const right = this.direction === "right"
      this.ray.style.left = right ? `${at}%` : "0"
      this.ray.style.width = right ? `calc(${100 - at}% - 6px)` : `calc(${at}% - 6px)`
      this.ray.style.marginLeft = right ? "0" : "6px"
      this.arrow.style.left = right ? "calc(100% - 4px)" : "-14px"
      this.arrow.classList.toggle("border-l-[18px]", right)
      this.arrow.classList.toggle("border-l-primary-300", right)
      this.arrow.classList.toggle("border-r-[18px]", !right)
      this.arrow.classList.toggle("border-r-primary-300", !right)
    }

    const complete = hasEdge && this.closed !== null && this.direction !== null
    this.readoutTarget.textContent = complete ? this.inequality() : ""
    this.hiddenTarget.value = complete
      ? JSON.stringify({ edge: this.edge, closed: this.closed, direction: this.direction })
      : ""
  }

  pickEdge(value) {
    this.edge = value
    this.buttons.forEach((button, i) => { button.tabIndex = this.ticks[i] === value ? 0 : -1 })
    this.render()
  }

  pickKind(event) {
    this.closed = event.currentTarget.dataset.value === "true"
    this.render()
  }

  pickDirection(event) {
    this.direction = event.currentTarget.dataset.value
    this.render()
  }

  // Arrow keys move the boundary along the line, and focus with it.
  nudge(event) {
    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return
    event.preventDefault()
    const index = this.edge === null ? Math.floor(this.ticks.length / 2) : this.ticks.indexOf(this.edge)
    const next = Math.min(Math.max(index + (event.key === "ArrowRight" ? 1 : -1), 0), this.ticks.length - 1)
    this.pickEdge(this.ticks[next])
    this.buttons[next].focus()
  }

  // Written the way Widgets.inequality_text writes it on the server.
  inequality() {
    const sign = this.direction === "right" ? (this.closed ? "≥" : ">") : (this.closed ? "≤" : "<")
    return `x ${sign} ${this.format(this.edge)}`
  }

  position(value) {
    return ((value - this.minValue) / (this.maxValue - this.minValue)) * 100
  }

  round(value) {
    return Math.round(value * 1000) / 1000
  }

  format(value) {
    const text = Number.isInteger(value) ? String(value) : String(value).replace(".", ",")
    return text.replace("-", "−")
  }
}
