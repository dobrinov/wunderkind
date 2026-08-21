import { Controller } from "@hotwired/stimulus"

// Coordinate-plot widget: the student clicks lattice points on a plane — plot
// A(3; −2), complete the rectangle, mark the image after a reflection.
// {points: [[x, y], ...]} is the answer state, submitted once the asked-for
// number of points is on the plane. Clicking a placed point removes it.
export default class extends Controller {
  static targets = ["canvas", "readout", "hidden"]
  static values = {
    minX: Number, maxX: Number, minY: Number, maxY: Number,
    count: Number, fixed: Array
  }

  connect() {
    this.points = []
    this.render()
  }

  render() {
    const size = 320
    const padding = 26
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("viewBox", `0 0 ${size} ${size}`)
    svg.setAttribute("class", "w-full max-w-[340px] touch-none select-none")

    const spanX = this.maxXValue - this.minXValue
    const spanY = this.maxYValue - this.minYValue
    const sx = (x) => padding + ((x - this.minXValue) / spanX) * (size - 2 * padding)
    const sy = (y) => size - padding - ((y - this.minYValue) / spanY) * (size - 2 * padding)

    for (let x = this.minXValue; x <= this.maxXValue; x++) svg.append(this.line(sx(x), sy(this.minYValue), sx(x), sy(this.maxYValue), "#e5e7eb", 1))
    for (let y = this.minYValue; y <= this.maxYValue; y++) svg.append(this.line(sx(this.minXValue), sy(y), sx(this.maxXValue), sy(y), "#e5e7eb", 1))
    svg.append(this.line(sx(this.minXValue), sy(0), sx(this.maxXValue), sy(0), "#111827", 2))
    svg.append(this.line(sx(0), sy(this.minYValue), sx(0), sy(this.maxYValue), "#111827", 2))

    for (let x = this.minXValue; x <= this.maxXValue; x += 2) {
      if (x === 0) continue
      svg.append(this.text(sx(x), sy(0) + 14, x, "#6b7280"))
    }
    for (let y = this.minYValue; y <= this.maxYValue; y += 2) {
      if (y === 0) continue
      svg.append(this.text(sx(0) - 12, sy(y) + 4, y, "#6b7280"))
    }

    this.fixedValue.forEach(([x, y, label]) => {
      svg.append(this.dot(sx(x), sy(y), 6, "#4338ca"))
      if (label) svg.append(this.text(sx(x) + 12, sy(y) - 9, label, "#4338ca"))
    })

    this.points.forEach(([x, y]) => svg.append(this.dot(sx(x), sy(y), 7, "#dc2626")))

    svg.addEventListener("click", (event) => {
      const rect = svg.getBoundingClientRect()
      const px = ((event.clientX - rect.left) / rect.width) * size
      const py = ((event.clientY - rect.top) / rect.height) * size
      const x = Math.round(this.minXValue + ((px - padding) / (size - 2 * padding)) * spanX)
      const y = Math.round(this.minYValue + ((size - padding - py) / (size - 2 * padding)) * spanY)
      if (x < this.minXValue || x > this.maxXValue || y < this.minYValue || y > this.maxYValue) return

      this.place(x, y)
    })

    this.canvasTarget.replaceChildren(svg)
    if (this.hasReadoutTarget) {
      this.readoutTarget.textContent = this.points.map(([x, y]) => `(${x}; ${y})`).join("  ")
    }
    this.hiddenTarget.value = this.points.length === this.countValue
      ? JSON.stringify({ points: this.points })
      : ""
  }

  place(x, y) {
    const at = this.points.findIndex(([px, py]) => px === x && py === y)
    if (at >= 0) this.points.splice(at, 1)
    else if (this.points.length < this.countValue) this.points.push([x, y])
    else this.points = [...this.points.slice(1), [x, y]]

    this.render()
  }

  line(x1, y1, x2, y2, stroke, width) {
    const line = document.createElementNS("http://www.w3.org/2000/svg", "line")
    Object.entries({ x1, y1, x2, y2, stroke, "stroke-width": width }).forEach(([key, value]) => line.setAttribute(key, value))
    return line
  }

  dot(cx, cy, r, fill) {
    const dot = document.createElementNS("http://www.w3.org/2000/svg", "circle")
    Object.entries({ cx, cy, r, fill }).forEach(([key, value]) => dot.setAttribute(key, value))
    return dot
  }

  text(x, y, content, fill) {
    const text = document.createElementNS("http://www.w3.org/2000/svg", "text")
    Object.entries({ x, y, fill, "font-size": 12, "text-anchor": "middle" }).forEach(([key, value]) => text.setAttribute(key, value))
    text.textContent = content
    return text
  }
}
