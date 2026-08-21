import { Controller } from "@hotwired/stimulus"

// Number line widget: the student places a point; {value} is the answer state.
export default class extends Controller {
  static targets = ["hidden", "readout"]
  static values = {
    min: Number,
    max: Number,
    step: { type: Number, default: 1 }
  }

  connect() {
    this.value = null
    this.render()
  }

  render() {
    const width = 600
    const height = 90
    const padding = 30
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`)
    svg.setAttribute("class", "w-full max-w-xl touch-none select-none")
    svg.setAttribute("role", "slider")
    svg.setAttribute("tabindex", "0")
    svg.setAttribute("aria-valuemin", this.minValue)
    svg.setAttribute("aria-valuemax", this.maxValue)

    const y = height / 2
    const axis = this.line(padding, y, width - padding, y, 3)
    svg.appendChild(axis)

    const range = this.maxValue - this.minValue
    const tickCount = Math.min(range / this.stepValue, 40)
    const tickStep = range / tickCount
    const values = Array.from({ length: tickCount + 1 }, (_, i) => this.minValue + i * tickStep)
    const every = this.labelEvery(values, (width - 2 * padding) / tickCount)
    values.forEach((value, i) => {
      const labelled = i % every === 0
      const x = this.xFor(value, width, padding)
      svg.appendChild(this.line(x, y - (labelled ? 8 : 5), x, y + (labelled ? 8 : 5), 2))
      if (!labelled) return
      const label = document.createElementNS("http://www.w3.org/2000/svg", "text")
      label.setAttribute("x", x)
      label.setAttribute("y", y + 28)
      label.setAttribute("text-anchor", "middle")
      label.setAttribute("class", "fill-current text-[13px]")
      label.textContent = this.format(value)
      svg.appendChild(label)
    })

    this.marker = document.createElementNS("http://www.w3.org/2000/svg", "circle")
    this.marker.setAttribute("r", 11)
    this.marker.setAttribute("cy", y)
    this.marker.setAttribute("class", "fill-[var(--color-accent,#4f46e5)] stroke-white stroke-2 cursor-grab drop-shadow")
    this.marker.setAttribute("visibility", "hidden")
    svg.appendChild(this.marker)

    svg.addEventListener("pointerdown", (event) => this.place(event, svg, width, padding))
    svg.addEventListener("pointermove", (event) => {
      if (event.buttons === 1) this.place(event, svg, width, padding)
    })
    svg.addEventListener("keydown", (event) => this.nudge(event))

    this.element.querySelector("[data-slot=canvas]").replaceChildren(svg)
    this.svg = svg
  }

  // Every tick still gets a mark, but only every nth gets a number: a line from
  // 0 to 4 in steps of 0,1 has 41 of them, and 41 numbers in 540 units are a
  // grey smear. n is the smallest spacing that fits the widest label, rounded
  // up to a divisor of the tick count so the last tick keeps its number.
  labelEvery(values, pitch) {
    const widest = Math.max(...values.map((value) => this.format(value).length)) * 7.5 + 8
    const needed = Math.ceil(widest / pitch)
    const ticks = values.length - 1
    for (let every = Math.max(needed, 1); every <= ticks; every++) {
      if (ticks % every === 0) return every
    }
    return Math.max(needed, 1)
  }

  place(event, svg, width, padding) {
    event.preventDefault()
    const rect = svg.getBoundingClientRect()
    const relative = ((event.clientX - rect.left) / rect.width) * width
    const fraction = (relative - padding) / (width - 2 * padding)
    const raw = this.minValue + fraction * (this.maxValue - this.minValue)
    this.setValue(this.snap(raw))
  }

  nudge(event) {
    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return
    event.preventDefault()
    const current = this.value ?? this.minValue
    const delta = event.key === "ArrowRight" ? this.stepValue : -this.stepValue
    this.setValue(this.snap(current + delta))
  }

  setValue(value) {
    this.value = value
    this.marker.setAttribute("visibility", "visible")
    this.marker.setAttribute("cx", this.xFor(value, 600, 30))
    this.svg.setAttribute("aria-valuenow", value)
    this.hiddenTarget.value = JSON.stringify({ value })
    if (this.hasReadoutTarget) this.readoutTarget.textContent = this.format(value)
  }

  snap(raw) {
    const snapped = Math.round((raw - this.minValue) / this.stepValue) * this.stepValue + this.minValue
    const clamped = Math.min(Math.max(snapped, this.minValue), this.maxValue)
    return Math.round(clamped * 1000) / 1000
  }

  xFor(value, width, padding) {
    const fraction = (value - this.minValue) / (this.maxValue - this.minValue)
    return padding + fraction * (width - 2 * padding)
  }

  format(value) {
    return Number.isInteger(value) ? value.toString() : value.toLocaleString("bg-BG")
  }

  line(x1, y1, x2, y2, strokeWidth) {
    const line = document.createElementNS("http://www.w3.org/2000/svg", "line")
    line.setAttribute("x1", x1)
    line.setAttribute("y1", y1)
    line.setAttribute("x2", x2)
    line.setAttribute("y2", y2)
    line.setAttribute("class", "stroke-current")
    line.setAttribute("stroke-width", strokeWidth)
    line.setAttribute("stroke-linecap", "round")
    return line
  }
}
