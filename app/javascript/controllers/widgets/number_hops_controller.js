import { Controller } from "@hotwired/stimulus"

// Number hops widget: adding or subtracting on an open number line. The student
// gets from {start} to {start + change} in hops of the sizes on offer — 37 + 25
// as +10, +10, +5 — and then writes where they landed. Landings are marked "?"
// rather than numbered: the arithmetic of each hop is the student's to do, and
// a line that printed 62 at the end would be the answer handed over.
// {hops: [signed sizes], value} is the answer state, submitted once the hops
// make the whole change and a landing number is written.
export default class extends Controller {
  static targets = ["line", "buttons", "chip", "value", "hidden"]
  static values = { start: Number, change: Number, hops: Array, labels: Object }

  connect() {
    this.taken = []
    this.render()
  }

  get sign() {
    return this.changeValue < 0 ? -1 : 1
  }

  get remaining() {
    return this.changeValue - this.taken.reduce((sum, hop) => sum + hop, 0)
  }

  hop(size) {
    if (size > Math.abs(this.remaining)) return
    this.taken.push(size * this.sign)
    this.render(true)
  }

  undo() {
    this.taken.pop()
    this.render()
  }

  sync() {
    const value = this.valueTarget.value.trim()
    this.hiddenTarget.value = this.remaining === 0 && value !== ""
      ? JSON.stringify({ hops: this.taken, value })
      : ""
  }

  render(animateLast = false) {
    this.renderLine(animateLast)
    this.renderButtons()
    this.renderChip()
    this.sync()
  }

  // The visible stretch of the line: the whole trip plus a margin, so the
  // first and last landings are never pressed against the edge.
  range() {
    const end = this.startValue + this.changeValue
    const low = Math.min(this.startValue, end)
    const high = Math.max(this.startValue, end)
    const pad = Math.max(2, Math.round((high - low) * 0.12))
    return [low - pad, high + pad]
  }

  renderLine(animateLast) {
    const [low, high] = this.range()
    const at = (value) => (value - low) / (high - low)
    const place = (element, value) => { element.style.left = `calc(12px + (100% - 24px) * ${at(value)})` }

    const axis = document.createElement("div")
    axis.className = "absolute left-3 right-3 top-[150px] h-1 rounded-full bg-ink-400"

    const parts = [axis]
    let position = this.startValue
    this.taken.forEach((hop, index) => {
      const from = position
      position += hop
      const width = Math.abs(at(position) - at(from))
      const height = Math.max(28, Math.min(110, width * 300))

      const arc = document.createElement("div")
      arc.className = "absolute box-border rounded-t-full border-4 border-b-0 border-primary-400"
      place(arc, Math.min(from, position))
      arc.style.width = `calc((100% - 24px) * ${width})`
      arc.style.height = `${height}px`
      arc.style.top = `${152 - height}px`

      const label = document.createElement("span")
      label.className = "absolute left-1/2 -top-7 -translate-x-1/2 whitespace-nowrap rounded-lg bg-primary-600 px-2 py-0.5 text-[15px] font-black text-white"
      label.textContent = this.signed(hop)
      arc.append(label)
      parts.push(arc)

      if (animateLast && index === this.taken.length - 1) this.pop(arc)
    })

    parts.push(this.mark(this.startValue, this.number(this.startValue), "text-ink-900", place))
    let landing = this.startValue
    this.taken.forEach((hop, index) => {
      landing += hop
      const last = index === this.taken.length - 1
      parts.push(this.mark(landing, "?", last ? "text-primary-700" : "text-ink-500", place))
    })

    this.lineTarget.replaceChildren(...parts)
  }

  mark(value, text, color, place) {
    const mark = document.createElement("div")
    mark.className = "absolute top-[140px] w-0"
    place(mark, value)
    mark.innerHTML = `<span class="absolute -left-0.5 h-6 w-1 rounded-sm bg-current ${color}"></span>`
    const label = document.createElement("span")
    label.className = `absolute top-8 -left-7 w-14 text-center text-lg font-black ${color}`
    label.textContent = text
    mark.append(label)
    return mark
  }

  pop(element) {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches || !element.animate) return
    element.animate([{ opacity: 0, transform: "translateY(10px)" }, { opacity: 1, transform: "none" }],
                    { duration: 280, easing: "ease-out" })
  }

  renderButtons() {
    const left = Math.abs(this.remaining)
    const sizes = [...new Set(this.hopsValue.map((size) => Math.abs(size)))].sort((a, b) => a - b)
    const buttons = sizes.map((size) => {
      const button = document.createElement("button")
      button.type = "button"
      button.textContent = this.signed(size * this.sign)
      button.disabled = size > left
      button.className = "min-h-12 min-w-16 flex-1 rounded-[14px] border-2 border-primary-300 bg-white px-3 text-lg font-black text-primary-800 transition-colors hover:bg-primary-50 disabled:cursor-not-allowed disabled:opacity-40"
      button.addEventListener("click", () => this.hop(size))
      return button
    })

    const undo = document.createElement("button")
    undo.type = "button"
    undo.textContent = this.labelsValue.undo
    undo.disabled = this.taken.length === 0
    undo.className = "min-h-12 rounded-[14px] border-2 border-ink-300 bg-white px-4 text-base font-black text-ink-700 hover:bg-ink-50 disabled:cursor-not-allowed disabled:opacity-40"
    undo.addEventListener("click", () => this.undo())

    this.buttonsTarget.replaceChildren(...buttons, undo)
  }

  renderChip() {
    const left = Math.abs(this.remaining)
    const done = left === 0
    this.chipTarget.textContent = done ? this.labelsValue.done : this.labelsValue.left.replace("%{count}", left)
    this.chipTarget.className = [
      "rounded-full px-3 py-1 text-sm font-black",
      done ? "bg-green-100 text-green-700" : "bg-ink-100 text-ink-600"
    ].join(" ")
  }

  signed(value) {
    return `${value < 0 ? "−" : "+"}${Math.abs(value)}`
  }

  number(value) {
    return value < 0 ? `−${Math.abs(value)}` : String(value)
  }
}
