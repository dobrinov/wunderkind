import { Controller } from "@hotwired/stimulus"

// „Какво е вероятност": a die rolled 1, 10 or 100 times. Each face gets a
// bar as long as its share of the rolls, the share written as a fraction of
// the rolls and as a percentage, with a dashed line at the 1/6 every face is
// expected to reach. The point is the randomness: after ten rolls the shares
// are all over the place, after a thousand they sit by the line. Every roll
// adds one to exactly one face, so the counts always add up to the total.
// The bars lie on their side so the three numbers beside each stay legible
// on a phone. A run stops at LIMIT rolls, which keeps the fractions short.
// A full strip stands for 100%, 50% or 34% — whichever is the smallest that
// holds the largest share — so the late, small differences can be seen; the
// line above the chart always says which, so a change of scale is announced
// rather than silent.
const SVG = "http://www.w3.org/2000/svg"
const FACES = 6
const LIMIT = 1000
const W = 340, TRACK = 34, LONG = 148, TOP = 34, ROW = 34, THICK = 22

// The share the full length of a bar stands for: the chart zooms in as the
// shares settle, in three fixed steps rather than continuously.
export function ceiling(largest) {
  if (largest > 0.5) return 1
  if (largest > 0.34) return 0.5
  return 0.34
}

export default class extends Controller {
  static targets = ["roll", "reset", "total", "scale", "figure", "spread", "note", "full"]
  static values = { copy: Object }

  connect() {
    this.reset()
  }

  reset() {
    this.counts = new Array(FACES).fill(0)
    this.render()
  }

  roll({ params }) {
    const times = Math.min(Number(params.count), LIMIT - this.total)
    for (let index = 0; index < times; index += 1) this.counts[Math.floor(Math.random() * FACES)] += 1
    this.render()
    // The button that was just pressed may have disabled itself at the limit:
    // hand the keyboard to „Отначало" rather than drop it.
    if (this.rollTargets.some((button) => button.disabled && button === document.activeElement)) this.resetTarget.focus()
  }

  get total() {
    return this.counts.reduce((sum, count) => sum + count, 0)
  }

  render() {
    const copy = this.copyValue
    const total = this.total
    const percent = (count) => {
      const exact = (count / total) * 100
      const shown = Math.round(exact * 10) / 10
      return `${Math.abs(exact - shown) < 1e-9 ? "" : "≈ "}${String(shown).replace(".", copy.point)}%`
    }

    this.totalTarget.textContent = copy.total.replaceAll("%{total}", total)
    this.rollTargets.forEach((button) => { button.disabled = total + Number(button.dataset.explainerDiceRollsCountParam) > LIMIT })
    this.spreadTarget.hidden = total === 0
    if (total > 0) {
      this.spreadTarget.textContent = copy.spread.replaceAll("%{max}", percent(Math.max(...this.counts))).replaceAll("%{min}", percent(Math.min(...this.counts)))
    }
    this.noteTarget.textContent = total === 0 ? copy.note_start : total < 30 ? copy.note_few : total < 300 ? copy.note_some : copy.note_many
    this.fullTarget.hidden = total < LIMIT

    const full = ceiling(total === 0 ? 0 : Math.max(...this.counts) / total)
    const fullText = `${Math.round(full * 100)}%`
    this.scaleTarget.textContent = copy.scale.replaceAll("%{full}", fullText)
    const label = total === 0 ? copy.figure_empty : copy.figure.replaceAll("%{total}", total).replaceAll("%{full}", fullText)
      .replaceAll("%{counts}", this.counts.map((count, face) => `${face + 1} — ${count}`).join(", "))
    this.figureTarget.replaceChildren(this.chart(total, full, percent, label))
  }

  chart(total, full, percent, label) {
    const svg = this.node("svg", { viewBox: `0 0 ${W} ${TOP + FACES * ROW + 4}`, class: "w-full max-w-[440px]", role: "img" })
    svg.setAttribute("aria-label", label)

    this.counts.forEach((count, face) => {
      const y = TOP + face * ROW
      svg.append(this.text(face + 1, 16, y + THICK / 2 + 6, "middle", "#312e81", 17))
      svg.append(this.node("rect", { x: TRACK, y, width: LONG, height: THICK, rx: 4, fill: "#ececf4" }))
      if (count > 0) svg.append(this.node("rect", { x: TRACK, y, width: Math.max((count / total / full) * LONG, 2), height: THICK, rx: 4, fill: "#5048e5" }))
      if (total > 0) {
        svg.append(this.text(`${count}/${total}`, 262, y + THICK / 2 + 5, "end", "#50506b", 14))
        svg.append(this.text(percent(count), 338, y + THICK / 2 + 5, "end", "#312e81", 14))
      }
    })

    // The expected share, 1/6, across every row.
    const expected = TRACK + (1 / FACES / full) * LONG
    svg.append(this.node("line", { x1: expected, y1: 24, x2: expected, y2: TOP + FACES * ROW - (ROW - THICK) + 4, stroke: "#312e81", "stroke-width": 2, "stroke-dasharray": "5 4" }))
    svg.append(this.text(this.copyValue.expected, Math.max(expected, 50), 16, "middle", "#312e81", 14))
    return svg
  }

  text(content, x, y, anchor, ink, size) {
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
