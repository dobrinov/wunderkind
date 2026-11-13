import { Controller } from "@hotwired/stimulus"

// „Как се решава текстова задача": four word problems as bar models. A bar
// is a row of segments, each as long as its number, so the bigger quantity
// always has the longer bar. The unknown is never a piece of a bar: it is a
// bracket reading „?" — under one bar or beside all of them for an unknown
// total, or spanning the gap from the end of the shorter bar to the end of
// the longer one for an unknown difference. The numbers and the shape of
// each drawing live here, in the order of the copy's `problems` (whose texts, bar names and
// solution sentences carry the same numbers): one-step total, „so many
// more", „how many more", and a two-step problem with two question marks.
// Revealing the solution turns every „?" into its number, in green.
const SVG = "http://www.w3.org/2000/svg"
const WIDTH = 360, UNIT = 18, ROW = 76, TOP = 8, BAR = 32
const FONT = 14   // 11px on a 390px phone, where the figure is ~290px wide

const PROBLEMS = [
  { bars: [[{ n: 7 }, { n: 5 }]], brackets: [{ under: 0, n: 12 }] },
  { bars: [[{ n: 8 }], [{ n: 8, same: true }, { n: 4 }]], brackets: [{ under: 1, n: 12 }] },
  { bars: [[{ n: 15 }], [{ n: 9 }]], brackets: [{ gap: 1, to: 0, n: 6 }] },
  { bars: [[{ n: 6 }], [{ n: 6, same: true }, { n: 3 }]], brackets: [{ under: 1, n: 9 }, { beside: true, n: 15 }] }
]

const length = (bar) => bar.reduce((sum, segment) => sum + segment.n, 0) * UNIT

export default class extends Controller {
  static targets = ["choice", "text", "figure", "hint", "solution", "reveal"]
  static values = { copy: Object }

  connect() {
    this.index = 0
    this.solved = false
    this.render()
  }

  choose(event) {
    this.index = Number(event.params.index)
    this.solved = false
    this.render()
  }

  reveal() {
    this.solved = !this.solved
    this.render()
  }

  render() {
    const copy = this.copyValue
    const words = copy.problems[this.index]

    this.choiceTargets.forEach((button, index) => button.setAttribute("aria-pressed", String(index === this.index)))
    this.textTarget.textContent = words.text
    this.hintTarget.hidden = this.solved
    this.solutionTarget.hidden = !this.solved
    this.solutionTarget.textContent = this.solved ? words.solution : ""
    this.revealTarget.textContent = this.solved ? copy.hide : copy.show
    this.figureTarget.replaceChildren(this.model(PROBLEMS[this.index], words.bars, this.solved ? copy.figure_solved : copy.figure))
  }

  model({ bars, brackets }, names, label) {
    const svg = this.node("svg", { viewBox: `0 0 ${WIDTH} ${TOP + bars.length * ROW + 10}`, class: "w-full max-w-[440px]", role: "img" })
    svg.setAttribute("aria-label", label)
    // Each row: the bar's name, the bar, and room for a bracket under it.
    const top = (row) => TOP + row * ROW + 20
    // The drawing is centred: the longest bar, plus the bracket beside it.
    const longest = Math.max(...bars.map(length))
    const beside = brackets.some((bracket) => bracket.beside) ? 44 : 0
    const left = (WIDTH - longest - beside) / 2

    bars.forEach((bar, row) => {
      svg.append(this.text(left, top(row) - 7, names[row], { "font-size": FONT, "font-weight": 800, fill: "#50506b" }))
      let x = left
      for (const segment of bar) {
        const width = segment.n * UNIT
        svg.append(this.node("rect", { x, y: top(row), width, height: BAR, rx: 6, "stroke-width": 2, fill: segment.same ? "#e2e4ff" : "#c9cdff", stroke: "#5048e5" }))
        svg.append(this.text(x + width / 2, top(row) + BAR / 2 + 6, segment.n, { "text-anchor": "middle", "font-size": 16, "font-weight": 900, fill: "#312e81" }))
        x += width
      }
    })

    for (const bracket of brackets) {
      const ink = this.solved ? "#15803d" : "#5048e5"
      const mark = this.solved ? bracket.n : "?"
      const stroke = { fill: "none", stroke: ink, "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round" }
      const words = { "font-size": 16, "font-weight": 900, fill: ink }
      if (bracket.beside) {
        // Beside all the bars: their total.
        const x = left + longest + 12
        const [y1, y2] = [top(0), top(bars.length - 1) + BAR]
        svg.append(this.node("path", { d: `M ${x - 6} ${y1} L ${x} ${y1} L ${x} ${y2} L ${x - 6} ${y2}`, ...stroke }))
        svg.append(this.text(x + 10, (y1 + y2) / 2 + 6, mark, words))
      } else if (bracket.gap !== undefined) {
        // In the empty space after the shorter bar: how much it is short of
        // the longer one. A dashed line drops from the longer bar's end, and
        // the bracket runs from the shorter bar's end to that line.
        const [x1, x2] = [left + length(bars[bracket.gap]) + 5, left + length(bars[bracket.to])]
        const y = top(bracket.gap) + BAR - 6
        svg.append(this.node("line", { x1: x2, y1: top(bracket.to) + BAR + 3, x2, y2: top(bracket.gap) + BAR, stroke: "#9a9ab0", "stroke-width": 1.5, "stroke-dasharray": "4 4" }))
        svg.append(this.node("path", { d: `M ${x1} ${y - 6} L ${x1} ${y} L ${x2 - 4} ${y} L ${x2 - 4} ${y - 6}`, ...stroke }))
        svg.append(this.text((x1 + x2 - 4) / 2, y - 8, mark, { "text-anchor": "middle", ...words }))
      } else {
        // Under one bar: the whole of it.
        const y = top(bracket.under) + BAR + 9
        const x2 = left + length(bars[bracket.under])
        svg.append(this.node("path", { d: `M ${left} ${y - 5} L ${left} ${y} L ${x2} ${y} L ${x2} ${y - 5}`, ...stroke }))
        svg.append(this.text((left + x2) / 2, y + 17, mark, { "text-anchor": "middle", ...words }))
      }
    }
    return svg
  }

  text(x, y, content, attributes) {
    const text = this.node("text", { x, y, ...attributes })
    text.textContent = content
    return text
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
