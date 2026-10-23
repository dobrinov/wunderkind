import { Controller } from "@hotwired/stimulus"

// „Окръжност и числото π": a disc of radius R cut into n equal slices, laid
// alternately point-up and point-down. Half the arcs line the bottom and half
// the top, so the row is half a circumference long (π·R) and R high — a
// rectangle with area π·R·R, more convincingly so the more slices there are.
const SVG = "http://www.w3.org/2000/svg"
const R = 70
const BASE = 120 // the up slices' chords; every layout stays R above it
const CENTRE = 320

export default class extends Controller {
  static targets = ["slices", "slicesOut", "figure"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const n = Number(this.slicesTarget.value)
    // Each slice is a true sector: its chord is 2R·sin(π/n), its point sits
    // R·cos(π/n) from the chord, and its arc bulges R·(1 − cos(π/n)) past it —
    // a lot at four slices, almost nothing at thirty-two.
    const half = Math.PI / n
    const chord = 2 * R * Math.sin(half)
    const height = R * Math.cos(half)
    const bulge = R - height
    const length = (n / 2 + 0.5) * chord
    const left = CENTRE - length / 2
    const parts = []

    for (let i = 0; i < n; i++) {
      const up = i % 2 === 0
      // Up slices stand on the bottom chord line with their point at the top;
      // down slices hang from the top between them, half a chord along.
      const x = left + (i * chord) / 2
      const chordY = up ? BASE : BASE - height
      const tip = [x + chord / 2, up ? BASE - height : BASE]
      const d = `M ${tip[0]} ${tip[1]} L ${x} ${chordY} A ${R} ${R} 0 0 ${up ? 0 : 1} ${x + chord} ${chordY} Z`
      parts.push(this.node("path", { d, fill: up ? "#7f7ff7" : "#fbbf24", stroke: "#ffffff", "stroke-width": 1.5 }))
    }

    // The length line goes under the lowest arc, so it never crosses a slice.
    const lineY = BASE + bulge + 10
    // It measures the up slices' chords — the row's bottom edge, n/2 chords,
    // which is what tends to π·R — not the row's whole width, which overhangs
    // by half a chord.
    const bottom = (n / 2) * chord
    parts.push(this.node("line", { x1: left, y1: lineY, x2: left + bottom, y2: lineY, stroke: "#ea580c", "stroke-width": 3, "stroke-dasharray": "7 5" }))
    const lengthLabel = this.node("text", { x: left + bottom / 2, y: lineY + 20, "text-anchor": "middle", "font-size": 15, "font-weight": 900, fill: "#9a3412" })
    lengthLabel.textContent = copy.length
    const heightLabel = this.node("text", { x: left - 14, y: BASE - height / 2 + 5, "text-anchor": "end", "font-size": 15, "font-weight": 900, fill: "#3730a3" })
    heightLabel.textContent = copy.height
    parts.push(lengthLabel, heightLabel)

    this.figureTarget.replaceChildren(...parts)
    this.figureTarget.setAttribute("aria-label", copy.figure.replace("%{n}", n))
    this.slicesOutTarget.textContent = n
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
