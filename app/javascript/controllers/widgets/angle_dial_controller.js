import { Controller } from "@hotwired/stimulus"

// Angle-dial widget: one ray is fixed, the other is dragged round a protractor.
// {degrees: n} is the answer state. Used both ways round — "set an angle of
// 135°" and "how big is the angle you see" — because the dial snaps to whole
// steps and the checker takes a tolerance.
export default class extends Controller {
  static targets = ["canvas", "readout", "hidden"]
  static values = { step: { type: Number, default: 5 }, max: { type: Number, default: 180 } }

  connect() {
    this.degrees = null
    this.render()
  }

  render() {
    // The vertex sits near the bottom edge with room for the dot below it, and
    // the box is only as tall as the labels above it need — a viewBox shorter
    // than the vertex clips away the very thing being measured.
    const size = 300
    const height = 152
    const cx = size / 2
    const cy = height - 12
    const radius = 118
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("viewBox", `0 0 ${size} ${height}`)
    svg.setAttribute("class", "w-full max-w-[320px] touch-none select-none")
    svg.setAttribute("role", "slider")
    svg.setAttribute("tabindex", "0")

    for (let angle = 0; angle <= this.maxValue; angle += 10) {
      const [x1, y1] = this.polar(cx, cy, radius - (angle % 30 === 0 ? 14 : 8), angle)
      const [x2, y2] = this.polar(cx, cy, radius, angle)
      svg.append(this.line(x1, y1, x2, y2, "#d1d5db", angle % 30 === 0 ? 2 : 1))
      if (angle % 30 === 0) {
        const [tx, ty] = this.polar(cx, cy, radius + 14, angle)
        svg.append(this.text(tx, ty + 4, angle))
      }
    }

    const [ax, ay] = this.polar(cx, cy, radius, 0)
    svg.append(this.line(cx, cy, ax, ay, "#4338ca", 3))

    if (this.degrees !== null) {
      const [bx, by] = this.polar(cx, cy, radius, this.degrees)
      svg.append(this.line(cx, cy, bx, by, "#dc2626", 3))
      svg.append(this.arc(cx, cy, 34, this.degrees))
    }

    const dot = document.createElementNS("http://www.w3.org/2000/svg", "circle")
    Object.entries({ cx, cy, r: 5, fill: "#111827" }).forEach(([key, value]) => dot.setAttribute(key, value))
    svg.append(dot)

    const place = (event) => {
      const rect = svg.getBoundingClientRect()
      const x = ((event.clientX - rect.left) / rect.width) * size - cx
      const y = cy - ((event.clientY - rect.top) / rect.height) * height
      const raw = (Math.atan2(y, x) * 180) / Math.PI
      this.set(Math.round(Math.min(Math.max(raw, 0), this.maxValue) / this.stepValue) * this.stepValue)
    }
    svg.addEventListener("pointerdown", place)
    svg.addEventListener("pointermove", (event) => { if (event.buttons === 1) place(event) })
    svg.addEventListener("keydown", (event) => {
      if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return
      event.preventDefault()
      const delta = event.key === "ArrowRight" ? -this.stepValue : this.stepValue
      this.set(Math.min(Math.max((this.degrees ?? 0) + delta, 0), this.maxValue))
    })

    this.canvasTarget.replaceChildren(svg)
    if (this.hasReadoutTarget) this.readoutTarget.textContent = this.degrees === null ? "" : `${this.degrees}°`
    this.hiddenTarget.value = this.degrees === null ? "" : JSON.stringify({ degrees: this.degrees })
  }

  set(degrees) {
    this.degrees = degrees
    this.render()
  }

  polar(cx, cy, radius, degrees) {
    const radians = (degrees * Math.PI) / 180
    return [cx + radius * Math.cos(radians), cy - radius * Math.sin(radians)]
  }

  arc(cx, cy, radius, degrees) {
    const [x1, y1] = this.polar(cx, cy, radius, 0)
    const [x2, y2] = this.polar(cx, cy, radius, degrees)
    const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
    path.setAttribute("d", `M ${x1} ${y1} A ${radius} ${radius} 0 ${degrees > 180 ? 1 : 0} 0 ${x2} ${y2}`)
    path.setAttribute("fill", "none")
    path.setAttribute("stroke", "#dc2626")
    path.setAttribute("stroke-width", 2)
    return path
  }

  line(x1, y1, x2, y2, stroke, width) {
    const line = document.createElementNS("http://www.w3.org/2000/svg", "line")
    Object.entries({ x1, y1, x2, y2, stroke, "stroke-width": width, "stroke-linecap": "round" }).
      forEach(([key, value]) => line.setAttribute(key, value))
    return line
  }

  text(x, y, content) {
    const text = document.createElementNS("http://www.w3.org/2000/svg", "text")
    Object.entries({ x, y, fill: "#6b7280", "font-size": 11, "text-anchor": "middle" }).
      forEach(([key, value]) => text.setAttribute(key, value))
    text.textContent = content
    return text
  }
}
