import { Controller } from "@hotwired/stimulus"

// Clock-hands widget: set the time on an analogue face. {hours, minutes} is the
// answer state. The hands are set with steppers rather than by dragging — a
// dragged minute hand is fiddly on a phone, and the point of the exercise is
// reading the dial, not aiming at it.
export default class extends Controller {
  static targets = ["canvas", "readout", "hidden"]
  static values = { minuteStep: { type: Number, default: 5 } }

  connect() {
    this.hours = 12
    this.minutes = 0
    this.touched = false
    this.render()
  }

  render() {
    const size = 240
    const cx = size / 2
    const cy = size / 2
    const radius = 96
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("viewBox", `0 0 ${size} ${size}`)
    svg.setAttribute("class", "w-full max-w-[260px]")

    svg.append(this.circle(cx, cy, radius))
    for (let hour = 1; hour <= 12; hour++) {
      const [x, y] = this.polar(cx, cy, radius - 22, 90 - hour * 30)
      svg.append(this.text(x, y + 5, hour))
    }

    const [hx, hy] = this.polar(cx, cy, radius * 0.5, 90 - ((this.hours % 12) + this.minutes / 60) * 30)
    const [mx, my] = this.polar(cx, cy, radius * 0.78, 90 - this.minutes * 6)
    svg.append(this.line(cx, cy, hx, hy, "#111827", 6))
    svg.append(this.line(cx, cy, mx, my, "#4338ca", 4))
    svg.append(this.circle(cx, cy, 4, "#111827"))

    this.canvasTarget.replaceChildren(svg)
    if (this.hasReadoutTarget) {
      this.readoutTarget.textContent = `${this.hours}:${String(this.minutes).padStart(2, "0")}`
    }
    this.hiddenTarget.value = this.touched
      ? JSON.stringify({ hours: this.hours, minutes: this.minutes })
      : ""
  }

  step(event) {
    const { unit, delta } = event.params
    this.touched = true
    if (unit === "hours") this.hours = ((this.hours - 1 + Number(delta) + 12) % 12) + 1
    else this.minutes = (this.minutes + Number(delta) * this.minuteStepValue + 60) % 60
    this.render()
  }

  polar(cx, cy, radius, degrees) {
    const radians = (degrees * Math.PI) / 180
    return [cx + radius * Math.cos(radians), cy - radius * Math.sin(radians)]
  }

  circle(cx, cy, r, fill = "none") {
    const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle")
    Object.entries({ cx, cy, r, fill, stroke: "#4338ca", "stroke-width": fill === "none" ? 3 : 0 }).
      forEach(([key, value]) => circle.setAttribute(key, value))
    return circle
  }

  line(x1, y1, x2, y2, stroke, width) {
    const line = document.createElementNS("http://www.w3.org/2000/svg", "line")
    Object.entries({ x1, y1, x2, y2, stroke, "stroke-width": width, "stroke-linecap": "round" }).
      forEach(([key, value]) => line.setAttribute(key, value))
    return line
  }

  text(x, y, content) {
    const text = document.createElementNS("http://www.w3.org/2000/svg", "text")
    Object.entries({ x, y, fill: "#111827", "font-size": 15, "font-weight": 700, "text-anchor": "middle" }).
      forEach(([key, value]) => text.setAttribute(key, value))
    text.textContent = content
    return text
  }
}
