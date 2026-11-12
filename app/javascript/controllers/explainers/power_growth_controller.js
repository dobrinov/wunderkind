import { Controller } from "@hotwired/stimulus"

// „Степени и корени": aⁿ for a base of 2, 3, 5 or 10 and n from 0 to 10. The
// power is written out as the product it stands for, and every power from a⁰
// to aⁿ gets a bar on one honest scale — the last bar fills the height and
// the earlier ones shrink to slivers, which is what "grows a times at every
// step" looks like. The last line asks the same fact backwards: which number
// to the power n gives this — the root. A bar too small for the scale is
// drawn as a sliver, and the note under the figure says so, because slivers
// of one height would otherwise contradict "a times taller".
const SVG = "http://www.w3.org/2000/svg"
const LEFT = 36, SLOT = 29, BAR = 21, BASE_LINE = 222, HEIGHT = 180
const SLIVER = 2              // the least height a bar is drawn with
const BOARD = 360, CHAR = 9.5 // the board's width, and a generous width per character of a label
// A line never ends on a lone sign: every =, ≈, ·, :, ÷, + or − that stands
// between spaces is tied to what follows it with a non-breaking space.
const tie = (text) => text.replace(/(?<=\s)([=≈·:÷+−]) /g, "$1\u00A0")
const SUPERSCRIPTS = "⁰¹²³⁴⁵⁶⁷⁸⁹"

// 10 as ¹⁰ — for exponents and for the index of a root.
const raised = (number) => String(number).split("").map((digit) => SUPERSCRIPTS[digit]).join("")

export default class extends Controller {
  static targets = ["base", "exponent", "exponentOut", "work", "figure", "step", "root"]
  static values = { copy: Object }

  connect() {
    this.base = 2
    this.render()
  }

  choose(event) {
    this.base = Number(event.params.base)
    this.baseTargets.forEach((button) => button.setAttribute("aria-pressed", button === event.currentTarget))
    this.render()
  }

  render() {
    const copy = this.copyValue
    const a = this.base
    const n = Number(this.exponentTarget.value)
    const value = a ** n
    // Digits in groups of three, with the locale's separator.
    const num = (number) => String(number).replace(/\B(?=(\d{3})+$)/g, copy.group)
    const power = `${a}${raised(n)}`
    const fill = (text) => tie(text)
      .replaceAll("%{a}", a).replaceAll("%{n}", n).replaceAll("%{power}", power)
      .replaceAll("%{value}", num(value)).replaceAll("%{previous}", num(value / a))
      .replaceAll("%{index}", raised(n))

    this.exponentOutTarget.textContent = n
    // 2⁴ = 2 · 2 · 2 · 2 = 16; with one factor or none there is no product
    // to write out.
    this.workTarget.textContent = tie(n >= 2
      ? `${power} = ${Array(n).fill(a).join(" · ")} = ${num(value)}`
      : `${power} = ${num(value)}`)
    // True of the picture only for bars tall enough to draw to scale.
    const slivers = HEIGHT * a ** -n < SLIVER
    this.stepTarget.textContent = fill(n === 0 ? copy.step_zero : copy.step) + (slivers ? ` ${copy.slivers}` : "")
    this.rootTarget.textContent = fill(
      n === 0 ? copy.root_zero : n === 1 ? copy.root_one : n === 2 ? copy.root_square : n === 3 ? copy.root_cube : copy.root_nth
    )
    this.figureTarget.replaceChildren(this.bars(a, n, `${power} = ${num(value)}`, fill(copy.figure)))
  }

  bars(a, n, valueLabel, label) {
    const svg = this.node("svg", { viewBox: "0 0 360 256", class: "w-full max-w-[460px]", role: "img" })
    svg.setAttribute("aria-label", label)
    svg.append(this.node("line", { x1: LEFT - 4, y1: BASE_LINE, x2: LEFT + 11 * SLOT + 2, y2: BASE_LINE, stroke: "#9a9ab0", "stroke-width": 2 }))

    // Under each bar its exponent only: eleven whole powers do not fit in a
    // row at a size a phone can show.
    svg.append(this.text("n", { x: 8, y: BASE_LINE + 22, "font-size": 15, "font-weight": 900, "font-style": "italic", fill: "#50506b" }))
    for (let k = 0; k <= n; k++) {
      // Every bar on the same scale as the tallest; one too small to draw
      // still gets a sliver, so it is seen to be there.
      const height = Math.max(SLIVER, HEIGHT * a ** (k - n))
      const x = LEFT + k * SLOT + (SLOT - BAR) / 2
      svg.append(this.node("rect", { x, y: BASE_LINE - height, width: BAR, height, rx: 2, fill: k === n ? "#5048e5" : "#a5aaff" }))
      svg.append(this.text(String(k), { x: x + BAR / 2, y: BASE_LINE + 22, "text-anchor": "middle", "font-size": 14, "font-weight": 900, fill: k === n ? "#312e81" : "#50506b" }))
    }

    // The value over the tallest bar, slid inwards so it stays on the board.
    const width = valueLabel.length * CHAR
    const centre = LEFT + n * SLOT + SLOT / 2
    const left = Math.max(6, Math.min(BOARD - 6 - width, centre - width / 2))
    svg.append(this.text(valueLabel, { x: left + width / 2, y: BASE_LINE - HEIGHT - 12, "text-anchor": "middle", "font-size": 16, "font-weight": 900, fill: "#312e81" }))
    return svg
  }

  text(content, attributes) {
    const element = this.node("text", attributes)
    element.textContent = content
    return element
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
