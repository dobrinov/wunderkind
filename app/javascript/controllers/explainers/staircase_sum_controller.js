import { Controller } from "@hotwired/stimulus"

// „Аритметична прогресия": the terms as a staircase of bars, each step d
// higher than the last. „Гаус" lays the same staircase upside down on top:
// column k then holds aₖ and aₙ₊₁₋ₖ, which always add up to a₁ + aₙ, so n
// equal columns are two sums — Sₙ = n(a₁ + aₙ) / 2 seen rather than derived.
// Every term stays at or above zero so it can be drawn. A slider never moves
// another slider: the one being dragged stops at the last value that keeps
// the last term at zero or above, and a note says why for as long as that
// slider is still held there.
const SVG = "http://www.w3.org/2000/svg"
const W = 340, BASE = 226, TALLEST = 186, GAP = 5
const SUBSCRIPT = "₀₁₂₃₄₅₆₇₈₉"

// The nearest value of the slider `moved` ("a", "d" or "n") that leaves no
// negative term, the other two being what they are; null when the numbers
// are already fine. Only d < 0 can make a term negative, and the last term
// is then the smallest.
export function held(moved, a1, d, n) {
  if (a1 + (n - 1) * d >= 0) return null
  if (moved === "d") return -Math.floor(a1 / (n - 1)) || 0
  if (moved === "n") return Math.floor(a1 / -d) + 1
  return (n - 1) * -d
}

// Whether one more step down (a₁, d) or up (n) on that slider would still be
// refused — the note stays while this is so.
export function stuck(moved, a1, d, n) {
  if (moved === "d") return d > -3 && a1 + (n - 1) * (d - 1) < 0
  if (moved === "n") return n < 8 && a1 + n * d < 0
  return a1 > 1 && a1 - 1 + (n - 1) * d < 0
}

export default class extends Controller {
  static targets = ["a", "d", "n", "aOut", "dOut", "nOut", "gauss", "figure", "term", "sum", "note", "clamped"]
  static values = { copy: Object }

  connect() {
    this.gauss = false
    this.blocked = null
    this.render()
  }

  toggle() {
    this.gauss = !this.gauss
    this.render()
  }

  render(event) {
    const copy = this.copyValue
    const sliders = { a: this.aTarget, d: this.dTarget, n: this.nTarget }
    const now = { a: Number(sliders.a.value), d: Number(sliders.d.value), n: Number(sliders.n.value) }
    const moved = Object.keys(sliders).find((name) => event && sliders[name] === event.target) || "a"
    const limit = held(moved, now.a, now.d, now.n)
    if (limit !== null) {
      now[moved] = limit
      sliders[moved].value = limit
      this.blocked = moved
    } else if (this.blocked && !stuck(this.blocked, now.a, now.d, now.n)) {
      this.blocked = null
    }
    const { a: a1, d, n } = now

    const terms = Array.from({ length: n }, (_, index) => a1 + index * d)
    const an = terms[n - 1]
    const pair = a1 + an
    const minus = (value) => (value < 0 ? `−${-value}` : String(value))
    const values = {
      a1, n, an, pair, steps: n - 1, sum: (n * pair) / 2, double: n * pair,
      d: d < 0 ? `(${minus(d)})` : d,
      sub: String(n).replace(/\d/g, (digit) => SUBSCRIPT[digit]),
      terms: terms.join(", ")
    }
    const fill = (text) => Object.entries(values).reduce((out, [key, value]) => out.replaceAll(`%{${key}}`, value), text)

    this.aOutTarget.textContent = a1
    this.dOutTarget.textContent = minus(d)
    this.nOutTarget.textContent = n
    this.gaussTarget.setAttribute("aria-pressed", this.gauss)
    this.termTarget.textContent = fill(copy.term)
    this.sumTarget.textContent = fill(copy.sum)
    this.noteTarget.textContent = fill(this.gauss ? copy.note_gauss : copy.note_plain)
    this.clampedTarget.hidden = !this.blocked
    this.figureTarget.replaceChildren(this.staircase(terms, pair, fill(this.gauss ? copy.figure_gauss : copy.figure)))
  }

  staircase(terms, pair, label) {
    const svg = this.node("svg", { viewBox: `0 0 ${W} 258`, class: "w-full max-w-[440px]", role: "img" })
    svg.setAttribute("aria-label", label)

    const n = terms.length
    // One unit of height, the same with and without the second copy, so the
    // toggle adds bars and moves none.
    const unit = Math.min(16, TALLEST / Math.max(pair, 1))
    const width = Math.min(40, (310 - (n - 1) * GAP) / n)
    const left = (W - (n * width + (n - 1) * GAP)) / 2

    svg.append(this.node("line", { x1: left - 8, y1: BASE, x2: W - left + 8, y2: BASE, stroke: "#9a9ab0", "stroke-width": 2, "stroke-linecap": "round" }))
    terms.forEach((term, index) => {
      const x = left + index * (width + GAP)
      const top = BASE - term * unit
      if (term > 0) svg.append(this.node("rect", { x, y: top, width, height: term * unit, rx: 3, fill: "#5048e5" }))
      if (this.gauss) {
        const partner = terms[n - 1 - index]
        if (partner > 0) svg.append(this.node("rect", { x, y: top - partner * unit, width, height: partner * unit, rx: 3, fill: "#c9cdff", stroke: "#a5aaff", "stroke-width": 1 }))
        svg.append(this.text(pair, x + width / 2, BASE - pair * unit - 8, "#50506b", 15))
      }
      svg.append(this.text(term, x + width / 2, BASE + 23, "#312e81", 17))
    })
    return svg
  }

  text(content, x, y, ink, size) {
    const text = this.node("text", { x, y, "text-anchor": "middle", "font-size": size, "font-weight": 900, fill: ink })
    text.textContent = content
    return text
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
