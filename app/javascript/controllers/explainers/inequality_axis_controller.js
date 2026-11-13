import { Controller } from "@hotwired/stimulus"

// „Неравенства": a·x + b against c, with any of the four signs. It is solved
// in the two lines a pupil writes — take b away from both sides, then divide
// by a — and the second line says in words whether the sign is kept or
// turned, because dividing by a negative number is the one place where an
// inequality is not an equation. The answer is then a picture: a dot at the
// boundary, hollow when the boundary is left out and solid when it belongs,
// and a ray over every number that works. The boundary is kept as a fraction
// rather than rounded.
const SVG = "http://www.w3.org/2000/svg"
// a = 0 leaves no x to solve for, so the a slider runs over these positions
// instead of over values — it steps from −1 straight to 1.
const A_VALUES = [-5, -4, -3, -2, -1, 1, 2, 3, 4, 5]
const OX = 180, AXIS = 56, UNIT = 13 // zero, the line's height and px per unit
const LIMIT = 10                      // |c − b| ≤ 10 and |a| ≥ 1, so the boundary is within ±10
const LEFT = 18, RIGHT = 342, TIP = 14 // the ends of the drawn line and the length of an arrowhead
const WIDTH = 360, CHAR = 10.5        // the board's width, and a generous width per character of a label
const TURNED = { "<": ">", ">": "<", "≤": "≥", "≥": "≤" }

const gcd = (a, b) => (b ? gcd(b, a % b) : a)
// A line never ends on a lone sign: every =, ≈, ·, :, ÷, + or − that stands
// between spaces is tied to what follows it with a non-breaking space.
const tie = (text) => text.replace(/(?<=\s)([=≈·:÷+−<>≤≥]) /g, "$1\u00A0")
// A whole number with a real minus.
const num = (value) => (value < 0 ? "−" : "") + Math.abs(value)

// top/bottom in lowest terms: "3", "−7/2".
function fraction(top, bottom) {
  const common = gcd(Math.abs(top), Math.abs(bottom)) || 1
  const sign = top * bottom < 0 ? "−" : ""
  const [p, q] = [Math.abs(top) / common, Math.abs(bottom) / common]
  return sign + (q === 1 ? String(p) : `${p}/${q}`)
}

// One term of an expression: no "1x", no "+ −3", nothing for a zero.
function term(coefficient, variable, first) {
  if (coefficient === 0) return ""
  const magnitude = Math.abs(coefficient)
  const shown = variable && magnitude === 1 ? "" : String(magnitude)
  const sign = coefficient < 0 ? (first ? "−" : " − ") : (first ? "" : " + ")
  return sign + shown + variable
}

export default class extends Controller {
  static targets = ["sign", "a", "b", "c", "aOut", "bOut", "cOut", "inequality", "first", "second", "figure", "answer"]
  static values = { copy: Object }

  connect() {
    this.sign = "<"
    this.render()
  }

  choose(event) {
    this.sign = String(event.params.sign)
    this.signTargets.forEach((button) => button.setAttribute("aria-pressed", button === event.currentTarget))
    this.render()
  }

  render() {
    const copy = this.copyValue
    const a = A_VALUES[Number(this.aTarget.value)]
    const b = Number(this.bTarget.value)
    const c = Number(this.cTarget.value)
    const sign = this.sign
    // Dividing by a negative a turns the sign round.
    const final = a < 0 ? TURNED[sign] : sign
    const rest = c - b
    const boundary = fraction(rest, a)
    const solution = `x ${final}\u00A0${boundary}`
    const open = final === "<" || final === ">"
    const right = final === ">" || final === "≥"
    const interval = right
      ? `${open ? "(" : "["}${boundary}${copy.separator}+∞)`
      : `(−∞${copy.separator}${boundary}${open ? ")" : "]"}`

    const fill = (text) => tie(text)
      .replaceAll("%{a}", num(a)).replaceAll("%{b}", Math.abs(b))
      .replaceAll("%{after}", `${term(a, "x", true)} ${sign}\u00A0${num(rest)}`)
      .replaceAll("%{solution}", solution).replaceAll("%{interval}", interval).replaceAll("%{boundary}", boundary)

    this.aOutTarget.textContent = num(a)
    this.bOutTarget.textContent = num(b)
    this.cOutTarget.textContent = num(c)
    this.inequalityTarget.textContent = tie(`${term(a, "x", true)}${term(b, "", false)} ${sign} ${num(c)}`)
    this.firstTarget.textContent = fill(b > 0 ? copy.subtract : b < 0 ? copy.add : copy.nothing_to_move)
    this.secondTarget.textContent = fill(a === 1 ? copy.divide_one : a > 0 ? copy.divide_positive : copy.divide_negative)
    // The line that turns the sign is set apart from the one that keeps it.
    this.secondTarget.classList.toggle("bg-primary-600", a < 0)
    this.secondTarget.classList.toggle("text-white", a < 0)
    this.secondTarget.classList.toggle("bg-ink-50", a > 0)
    this.secondTarget.classList.toggle("text-ink-800", a > 0)
    this.answerTarget.textContent = fill(copy.answer)

    const label = fill(open ? copy.figure_open : copy.figure_closed)
    this.figureTarget.replaceChildren(this.axis(rest / a, boundary, open, right, label))
  }

  axis(value, boundary, open, right, label) {
    const px = (x) => OX + x * UNIT
    const svg = this.node("svg", { viewBox: "0 0 360 104", class: "w-full max-w-[460px]", role: "img" })
    svg.setAttribute("aria-label", label)

    // The number line with its arrow, a tick for every whole number and a
    // number under every fifth. It runs on past ±10 at both ends, so a ray
    // from a boundary at the very edge still has somewhere to go.
    svg.append(this.node("line", { x1: LEFT, y1: AXIS, x2: RIGHT, y2: AXIS, stroke: "#9a9ab0", "stroke-width": 2 }))
    svg.append(this.node("path", { d: `M ${RIGHT + TIP} ${AXIS} L ${RIGHT} ${AXIS - 5} L ${RIGHT} ${AXIS + 5} Z`, fill: "#9a9ab0" }))
    for (let x = -LIMIT; x <= LIMIT; x++) {
      const major = x % 5 === 0
      svg.append(this.node("line", { x1: px(x), y1: AXIS - (major ? 8 : 4), x2: px(x), y2: AXIS + (major ? 8 : 4), stroke: "#9a9ab0", "stroke-width": major ? 2 : 1 }))
      if (major) svg.append(this.text(num(x), { x: px(x), y: AXIS + 28, "text-anchor": "middle", "font-size": 15, "font-weight": 800, fill: "#50506b" }))
    }

    // The ray over the solutions, to the end of the line and past it.
    const end = right ? RIGHT : LEFT
    const tip = right ? RIGHT + TIP : LEFT - TIP
    svg.append(this.node("line", { x1: px(value), y1: AXIS, x2: end, y2: AXIS, stroke: "#5048e5", "stroke-width": 6 }))
    svg.append(this.node("path", { d: `M ${tip} ${AXIS} L ${end} ${AXIS - 9} L ${end} ${AXIS + 9} Z`, fill: "#5048e5" }))
    svg.append(this.node("circle", { cx: px(value), cy: AXIS, r: 7, fill: open ? "#ffffff" : "#5048e5", stroke: "#5048e5", "stroke-width": 3 }))

    // The boundary over its dot, slid inwards so it stays on the board.
    const width = boundary.length * CHAR
    const left = Math.max(4, Math.min(WIDTH - 4 - width, px(value) - width / 2))
    svg.append(this.text(boundary, { x: left + width / 2, y: AXIS - 20, "text-anchor": "middle", "font-size": 17, "font-weight": 900, fill: "#312e81" }))
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
