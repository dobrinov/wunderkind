import { Controller } from "@hotwired/stimulus"

// „Какво е просто число?": n dots arranged into every rectangle n makes. A
// prime has exactly one — the long row — and that is the whole definition,
// seen rather than recited.
const MAX = 36

export default class extends Controller {
  static targets = ["count", "verdict", "shapes", "dots", "note"]
  static values = { copy: Object, n: { type: Number, default: 12 } }

  connect() {
    this.pick(this.nValue)
  }

  less() { this.pick(this.nValue - 1) }
  more() { this.pick(this.nValue + 1) }

  pick(n) {
    this.nValue = Math.max(1, Math.min(MAX, n))
    const pairs = this.rectangles(this.nValue)
    // Start on the squarest arrangement: the long row is the boring one.
    this.rows = pairs[Math.floor((pairs.length - 1) / 2)][0]
    this.render()
  }

  rectangles(n) {
    const pairs = []
    for (let rows = 1; rows <= n; rows++) if (n % rows === 0) pairs.push([rows, n / rows])
    return pairs
  }

  render() {
    const n = this.nValue
    const pairs = this.rectangles(n)
    const kind = n === 1 ? "one" : pairs.length === 2 ? "prime" : "composite"
    const copy = this.copyValue

    this.countTarget.textContent = n
    this.verdictTarget.textContent = copy[kind]
    this.verdictTarget.className = [
      "ml-auto rounded-full px-3.5 py-1.5 text-[15px] font-black",
      kind === "prime" ? "bg-green-100 text-green-800" : kind === "one" ? "bg-gray-100 text-gray-700" : "bg-reward-100 text-reward-800"
    ].join(" ")

    this.shapesTarget.replaceChildren(...pairs.map(([rows, cols]) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "play-key"
      button.textContent = copy.arrangement.replace("%{rows}", rows).replace("%{cols}", cols)
      button.setAttribute("aria-pressed", rows === this.rows)
      button.addEventListener("click", () => { this.rows = rows; this.render() })
      return button
    }))

    // The columns shrink with the room there is, so a prime's single row of 36
    // dots still fits a phone instead of running off the card — every dot the
    // number says is there has to be visible.
    const cols = n / this.rows
    this.dotsTarget.style.gridTemplateColumns = `repeat(${cols}, minmax(0, 1.1rem))`
    this.dotsTarget.style.gap = cols > 12 ? "2px" : "6px"
    this.dotsTarget.style.width = "100%"
    this.dotsTarget.style.justifyContent = "center"
    const label = this.rows === 1 ? copy.figure_row : copy.figure
    this.dotsTarget.setAttribute("aria-label", label.replace("%{n}", n).replace("%{rows}", this.rows).replace("%{cols}", cols))
    this.dotsTarget.replaceChildren(...Array.from({ length: n }, () => {
      const dot = document.createElement("span")
      dot.className = "block aspect-square w-full rounded-full bg-primary-400"
      return dot
    }))

    const note = kind === "one" ? copy.explain_one : kind === "prime" ? copy.explain_prime : copy.explain_composite
    // The count is of divisors, not of arrangements: 3 × 4 and 4 × 3 are one
    // rectangle turned round, but 3 and 4 are two divisors of 12.
    this.noteTarget.textContent = note.replaceAll("%{n}", n).replace("%{count}", pairs.length)
  }
}
