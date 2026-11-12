import { Controller } from "@hotwired/stimulus"

// „Събиране и изваждане през десетицата": one sum on a number line from 0 to
// 20. A jump that passes 10 is drawn as two hops — to the ten, then the rest
// — because that split is the whole method, and the working underneath is the
// same split in numbers. A jump that does not pass 10 is one hop, and the
// note says so.
//
// Switching to subtraction always starts from the sum's answer with the same
// amount, so 8 + 5 = 13 turns into 13 − 5 = 8 on the same stretch of the
// line, and back again. That is why the start may be anything on the line
// (0–19 to add, 1–20 to subtract) and it is the amount's slider that is cut
// short — to what is left of the line — to keep every answer on it.
//
// Twenty-one numbers do not fit under the line at a size a phone can read,
// so only the fives are written, plus the three that matter — the start, the
// landing and the ten between them — in bold; the ticks are there to count
// along. A bold label with no room beside its neighbour drops to a second
// row.
const SVG = "http://www.w3.org/2000/svg"
const WIDTH = 336, HEIGHT = 120, LEFT = 18, STEP = 15, LINE_Y = 74
const FONT = 13          // 11px on a 390px phone, where the figure is ~290px wide
const DIGIT = FONT * 0.62 // a bold digit's width, near enough

const at = (number) => LEFT + number * STEP
const width = (number) => String(number).length * DIGIT
const crowded = (one, other) => Math.abs(one - other) * STEP < (width(one) + width(other)) / 2 + 3

// Where the jump lands, and — when it passes 10 — the two parts of it.
const plan = (start, amount, mode) => {
  const result = mode === "add" ? start + amount : start - amount
  const crosses = mode === "add" ? start < 10 && result > 10 : start > 10 && result < 10
  const first = Math.abs(10 - start)
  return { result, crosses, first, second: amount - first, exact: result === 10 }
}

export default class extends Controller {
  static targets = ["mode", "start", "amount", "startOut", "amountOut", "amountLabel", "figure", "work", "note"]
  static values = { copy: Object }

  connect() {
    // The article's own example first: 8 + 5.
    this.mode = "add"
    this.render()
  }

  // The other operation, starting where this one landed, by the same amount.
  switch(event) {
    const mode = event.params.mode
    if (mode === this.mode) return
    const { result } = plan(Number(this.startTarget.value), Number(this.amountTarget.value), this.mode)
    this.mode = mode
    this.startTarget.min = mode === "add" ? 0 : 1
    this.startTarget.max = mode === "add" ? 19 : 20
    this.startTarget.value = result
    this.render()
  }

  render() {
    const copy = this.copyValue
    const mode = this.mode
    const start = Number(this.startTarget.value)

    // The amount can be at most what is left of the line on that side.
    const room = Math.min(9, mode === "add" ? 20 - start : start)
    this.amountTarget.max = room
    if (Number(this.amountTarget.value) > room) this.amountTarget.value = room
    const amount = Number(this.amountTarget.value)

    const { result, crosses, first, second, exact } = plan(start, amount, mode)
    const sign = mode === "add" ? "+" : "−"
    const fill = (text) => text.replaceAll("%{a}", start).replaceAll("%{b}", amount).replaceAll("%{p}", first)
      .replaceAll("%{q}", second).replaceAll("%{r}", result)
    const many = (count) => (count === 1 ? "one" : "many")

    this.modeTargets.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.getAttribute("data-explainer-number-line-jump-mode-param") === mode))
    })
    this.amountLabelTarget.textContent = copy[`${mode}_label`]
    this.startOutTarget.textContent = start
    this.amountOutTarget.textContent = `${sign}${amount}`
    this.workTarget.textContent = fill(copy[`${mode}_${crosses ? "cross" : "single"}`])
    this.noteTarget.textContent = crosses
      ? fill([copy[`${mode}_first_${many(first)}`], copy[`rest_${many(second)}`], copy[`${mode}_then`]].join(" "))
      : exact ? copy.exact_note : copy.single_note

    const hops = crosses ? [[start, 10, first], [10, result, second]] : [[start, result, amount]]
    this.figureTarget.replaceChildren(this.line(start, result, crosses, hops, sign, fill(copy.figure)))
  }

  line(start, result, crosses, hops, sign, label) {
    const svg = this.node("svg", { viewBox: `0 0 ${WIDTH} ${HEIGHT}`, class: "w-full max-w-[560px]", role: "img" })
    svg.setAttribute("aria-label", label)

    // The numbers that matter, each on the first row unless a neighbour
    // already there leaves it no room.
    const marked = crosses ? [start, 10, result] : [start, result]
    const rows = new Map()
    for (const number of marked) {
      const taken = [...rows].some(([other, row]) => row === 0 && crowded(number, other))
      rows.set(number, taken ? 1 : 0)
    }

    svg.append(this.node("line", { x1: at(0), y1: LINE_Y, x2: at(20), y2: LINE_Y, stroke: "#9a9ab0", "stroke-width": 2, "stroke-linecap": "round" }))
    for (let number = 0; number <= 20; number++) {
      const bold = rows.has(number)
      const five = number % 5 === 0
      const reach = bold || five ? 6 : 4
      svg.append(this.node("line", { x1: at(number), y1: LINE_Y - reach, x2: at(number), y2: LINE_Y + reach, stroke: bold ? "#5048e5" : "#9a9ab0", "stroke-width": bold ? 2.5 : 1.5 }))
      // A five is written unless a bold number stands on it or beside it.
      if (!bold && !(five && !marked.some((other) => crowded(number, other)))) continue
      const text = this.node("text", { x: at(number), y: LINE_Y + 21 + (rows.get(number) || 0) * 17, "text-anchor": "middle", "font-size": FONT, "font-weight": bold ? 900 : 700, fill: bold ? "#312e81" : "#666680" })
      text.textContent = number
      svg.append(text)
    }

    // Two hops meet at 10; their sizes are nudged apart so „+1" and „+1"
    // do not run together.
    hops.forEach(([from, to, size], index) => {
      const outward = hops.length === 1 ? 0 : (index === 0 ? -1 : 1) * Math.sign(to - from) * 5
      this.hop(svg, from, to, `${sign}${size}`, outward)
    })

    if (crosses) svg.append(this.node("circle", { cx: at(10), cy: LINE_Y, r: 4.5, fill: "#ffffff", stroke: "#5048e5", "stroke-width": 2.5 }))
    svg.append(this.node("circle", { cx: at(start), cy: LINE_Y, r: 5, fill: "#5048e5" }))
    svg.append(this.node("circle", { cx: at(result), cy: LINE_Y, r: 5, fill: "#312e81" }))
    return svg
  }

  // One hop: an arc over the line, taller the further it goes, with an
  // arrowhead where it lands and its size written above it.
  hop(svg, from, to, label, nudge) {
    const base = LINE_Y - 8
    const peak = 16 + 3 * Math.abs(to - from)
    const [x1, x2] = [at(from), at(to)]
    const middle = (x1 + x2) / 2
    const top = base - 2 * peak
    svg.append(this.node("path", { d: `M ${x1} ${base} Q ${middle} ${top} ${x2} ${base}`, fill: "none", stroke: "#5048e5", "stroke-width": 2.5, "stroke-linecap": "round" }))

    // The arrowhead follows the arc's direction at its end.
    const [dx, dy] = [x2 - middle, base - top]
    const length = Math.hypot(dx, dy)
    const [ux, uy] = [dx / length, dy / length]
    const [bx, by] = [x2 - ux * 9, base - uy * 9]
    svg.append(this.node("path", { d: `M ${x2} ${base} L ${bx - uy * 4.5} ${by + ux * 4.5} L ${bx + uy * 4.5} ${by - ux * 4.5} Z`, fill: "#5048e5" }))

    const text = this.node("text", { x: middle + nudge, y: base - peak - 7, "text-anchor": "middle", "font-size": FONT, "font-weight": 900, fill: "#312e81" })
    text.textContent = label
    svg.append(text)
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
