import { Controller } from "@hotwired/stimulus"

// „Геометрична прогресия": a ball dropped from h that rises to the fraction
// q of its last height. The first six heights h, hq, hq², … are drawn as bars
// on one fixed scale (so a higher drop is a taller picture). The first n are
// added by the formula, and a strip under the bars is the point of the
// exercise: its whole length is h / (1 − q) — a whole number for each of the
// four ratios offered — and the sum fills it, quickly at first and then by
// less and less, without ever reaching the end. n runs to 40 so that even
// q = 0,9 gets close. A value that had to be rounded is written after ≈.
const SVG = "http://www.w3.org/2000/svg"
const BARS = 6
const W = 340, BASE = 172, METRE = 14, WIDTH = 40, GAP = 12
const STRIP = { left: 20, right: 320, top: 228, thick: 16 }
const SUBSCRIPT = "₀₁₂₃₄₅₆₇₈₉"
const SUPERSCRIPT = "⁰¹²³⁴⁵⁶⁷⁸⁹"
// The last ratio's label needs the locale's decimal mark, so it is made from
// the number when it is shown.
export const RATIOS = [{ value: 1 / 2, label: "½" }, { value: 2 / 3, label: "⅔" }, { value: 3 / 4, label: "¾" }, { value: 0.9 }]

export default class extends Controller {
  static targets = ["h", "n", "hOut", "nOut", "ratio", "figure", "term", "sum", "limit", "note"]
  static values = { copy: Object }

  connect() {
    this.index = 0
    this.render()
  }

  choose({ params }) {
    this.index = Number(params.index)
    this.render()
  }

  render() {
    const copy = this.copyValue
    const h = Number(this.hTarget.value)
    const n = Number(this.nTarget.value)
    const ratio = RATIOS[this.index]
    const q = ratio.value

    const round = (value) => Math.round(value * 100) / 100
    const num = (value) => String(round(value)).replace(".", copy.point)
    const rel = (value) => (Math.abs(value - round(value)) < 1e-9 ? "=" : "≈")
    const plain = ratio.label || num(q)
    const heights = Array.from({ length: BARS }, (_, index) => h * q ** index)
    const term = h * q ** (n - 1)
    const sum = (h * (1 - q ** n)) / (1 - q)
    const limit = h / (1 - q)
    const small = (number, digits) => String(number).replace(/\d/g, (digit) => digits[digit])
    const approx = (value) => `${rel(value)} ${num(value)}`
    const values = {
      h, n,
      ratio: plain,
      q: ratio.label ? `(${plain})` : plain,
      sub: small(n, SUBSCRIPT),
      power: small(n - 1, SUPERSCRIPT),
      power_n: small(n, SUPERSCRIPT),
      term: num(term), rel_term: rel(term),
      sum: num(sum), rel_sum: rel(sum),
      limit: num(limit)
    }
    const fill = (text) => Object.entries(values).reduce((out, [key, value]) => out.replaceAll(`%{${key}}`, value), text)

    this.hOutTarget.textContent = h
    this.nOutTarget.textContent = n
    this.ratioTargets.forEach((button, index) => button.setAttribute("aria-pressed", index === this.index))
    this.termTarget.textContent = fill(copy.term)
    this.sumTarget.textContent = fill(copy.sum)
    this.limitTarget.textContent = fill(copy.limit)
    this.noteTarget.textContent = fill(copy.note)
    const svg = this.bars(heights, n, (value) => (rel(value) === "=" ? num(value) : approx(value)), fill(copy.figure))
    this.strip(svg, sum / limit, `S${values.sub} ${approx(sum)}`, `S = ${num(limit)}`)
    this.figureTarget.replaceChildren(svg)
  }

  bars(heights, n, caption, label) {
    const svg = this.node("svg", { viewBox: `0 0 ${W} 254`, class: "w-full max-w-[440px]", role: "img" })
    svg.setAttribute("aria-label", label)

    const left = (W - (BARS * WIDTH + (BARS - 1) * GAP)) / 2
    svg.append(this.node("line", { x1: left - 8, y1: BASE, x2: W - left + 8, y2: BASE, stroke: "#9a9ab0", "stroke-width": 2, "stroke-linecap": "round" }))
    heights.forEach((height, index) => {
      const x = left + index * (WIDTH + GAP)
      const tall = Math.max(height * METRE, 1.5)
      const counted = index < n
      svg.append(this.node("rect", { x, y: BASE - tall, width: WIDTH, height: tall, rx: 3, fill: counted ? "#5048e5" : "#c9cdff" }))
      svg.append(this.text(caption(height), x + WIDTH / 2, BASE - tall - 7, counted ? "#312e81" : "#666680", 14, "middle"))
      svg.append(this.text(index + 1, x + WIDTH / 2, BASE + 19, "#50506b", 14, "middle"))
    })
    return svg
  }

  // The sum so far as a strip whose whole length is the sum of all the
  // heights; the dark line at its end is the number the sum never reaches.
  strip(svg, share, sumLabel, limitLabel) {
    const long = STRIP.right - STRIP.left
    svg.append(this.text(sumLabel, STRIP.left, STRIP.top - 8, "#5048e5", 15, "start"))
    svg.append(this.text(limitLabel, STRIP.right, STRIP.top - 8, "#312e81", 15, "end"))
    svg.append(this.node("rect", { x: STRIP.left, y: STRIP.top, width: long, height: STRIP.thick, rx: 4, fill: "#e2e4ff" }))
    svg.append(this.node("rect", { x: STRIP.left, y: STRIP.top, width: Math.max(long * Math.min(share, 1), 2), height: STRIP.thick, rx: 4, fill: "#5048e5" }))
    svg.append(this.node("line", { x1: STRIP.right, y1: STRIP.top - 4, x2: STRIP.right, y2: STRIP.top + STRIP.thick + 4, stroke: "#312e81", "stroke-width": 3, "stroke-linecap": "round" }))
  }

  text(content, x, y, ink, size, anchor) {
    const text = this.node("text", { x, y, "text-anchor": anchor, "font-size": size, "font-weight": 900, fill: ink })
    text.textContent = content
    return text
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
