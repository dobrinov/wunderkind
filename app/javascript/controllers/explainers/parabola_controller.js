import { Controller } from "@hotwired/stimulus"

// „Квадратни уравнения": y = ax² + bx + c drawn on a grid as a, b and c move.
// The roots are marked where the curve meets the x-axis, and the discriminant
// and the formula are worked with the very numbers on the sliders, so the
// arithmetic and the picture are the same thing said twice.
const SVG = "http://www.w3.org/2000/svg"
// a = 0 is not a quadratic, so the a slider runs over these positions instead
// of over values — it steps from −0,5 straight to 0,5.
const A_VALUES = [ -3, -2.5, -2, -1.5, -1, -0.5, 0.5, 1, 1.5, 2, 2.5, 3 ]
const OX = 260, OY = 180, SX = 40, SY = 20 // origin and px per unit on the board
const X_MAX = 6, Y_MAX = 8
const WIDTH = 520, CHAR = 10 // the board's width, and a generous width per character of a label

// A number the way the page writes it: a decimal comma and a real minus,
// rounded to two places.
function num(value) {
  const rounded = Math.round(value * 100) / 100
  const text = String(Math.abs(rounded)).replace(".", ",")
  return (rounded < 0 ? "−" : "") + text
}

// "= 3" when the number is exact, "≈ 1,79" when it had to be rounded — the
// sign belongs where the equals sign would be, never after it.
function rel(value) {
  return (Math.abs(Math.round(value * 100) / 100 - value) > 1e-9 ? "≈ " : "= ") + num(value)
}

// A negative number inside a sum or under a division gets brackets.
function paren(value) {
  return value < 0 ? `(${num(value)})` : num(value)
}

// √D in the formula: the whole number when D is a perfect square, else √D
// itself — a rounded 5,39 there would make the next line look exact.
function sqrt(D) {
  const root = Math.round(Math.sqrt(D))
  return root * root === D ? String(root) : `√${D}`
}

// Each label under its dot, slid inwards so the text stays on the board and
// dropped a row when it would run into its neighbour's.
function placeLabels(items) {
  const placed = []
  for (const item of items) {
    const width = item.text.length * CHAR
    const left = Math.max(6, Math.min(WIDTH - 6 - width, item.x - width / 2))
    const clash = placed.some((other) => left < other.left + other.width + 8 && other.left < left + width + 8)
    placed.push({ ...item, left, width, row: clash ? 1 : 0 })
  }
  return placed
}

// One term of the equation: no "1x", no "+ −3", nothing for a zero.
function term(coefficient, variable, first) {
  if (coefficient === 0) return ""
  const magnitude = Math.abs(coefficient)
  const shown = variable && magnitude === 1 ? "" : String(magnitude).replace(".", ",")
  const sign = coefficient < 0 ? (first ? "−" : " − ") : (first ? "" : " + ")
  return sign + shown + variable
}

export default class extends Controller {
  static targets = ["a", "b", "c", "aOut", "bOut", "cOut", "equation", "figure", "dWork", "verdict", "xWork"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const a = A_VALUES[Number(this.aTarget.value)]
    const b = Number(this.bTarget.value)
    const c = Number(this.cTarget.value)
    const D = b * b - 4 * a * c
    // x₁ takes the plus and x₂ the minus, as the formula reads and the text says.
    const roots = D > 0 ? [ (-b + Math.sqrt(D)) / (2 * a), (-b - Math.sqrt(D)) / (2 * a) ]
      : D === 0 ? [ -b / (2 * a) ] : []
    const equation = term(a, "x²", true) + term(b, "x", false) + term(c, "", false) + " = 0"

    this.aOutTarget.textContent = num(a)
    this.bOutTarget.textContent = num(b)
    this.cOutTarget.textContent = num(c)
    this.equationTarget.textContent = equation

    const kind = D > 0 ? "two" : D === 0 ? "one" : "none"
    this.figureTarget.replaceChildren(this.graph(a, b, c, roots, copy[`figure_${kind}`].replace("%{equation}", equation)))

    this.dWorkTarget.textContent = copy.d_work
      .replace("%{work}", `${paren(b)}² − 4 · ${paren(a)} · ${paren(c)}`)
      .replace("%{d}", num(D))

    this.verdictTarget.textContent = copy[`verdict_${kind}`]
    this.verdictTarget.className = [
      "rounded-[12px] px-4 py-2.5 text-[16px] font-extrabold",
      kind === "two" ? "bg-green-50 text-green-800" : kind === "one" ? "bg-primary-50 text-primary-800" : "bg-reward-50 text-reward-800"
    ].join(" ")

    if (kind === "two") {
      this.xWorkTarget.textContent = copy.x_two
        .replace("%{minus_b}", num(-b)).replace("%{root}", sqrt(D)).replace("%{two_a}", paren(2 * a))
        .replace("%{x1}", rel(roots[0])).replace("%{x2}", rel(roots[1]))
    } else if (kind === "one") {
      this.xWorkTarget.textContent = copy.x_one
        .replace("%{minus_b}", num(-b)).replace("%{two_a}", paren(2 * a)).replace("%{x}", rel(roots[0]))
    } else {
      this.xWorkTarget.textContent = copy.x_none
    }
  }

  graph(a, b, c, roots, label) {
    const copy = this.copyValue
    const px = (x) => OX + x * SX
    const py = (y) => OY - y * SY
    const svg = this.node("svg", { viewBox: "0 0 520 360", class: "w-full max-w-[560px]", role: "img" })
    svg.setAttribute("aria-label", label)

    for (let x = -X_MAX; x <= X_MAX; x++) {
      svg.append(this.node("line", { x1: px(x), y1: py(Y_MAX) - 10, x2: px(x), y2: py(-Y_MAX) + 10, stroke: x === 0 ? "#9a9ab0" : "#ececf4", "stroke-width": x === 0 ? 2 : 1 }))
    }
    for (let y = -Y_MAX; y <= Y_MAX; y += 2) {
      svg.append(this.node("line", { x1: px(-X_MAX) - 10, y1: py(y), x2: px(X_MAX) + 10, y2: py(y), stroke: y === 0 ? "#9a9ab0" : "#ececf4", "stroke-width": y === 0 ? 2 : 1 }))
    }

    // The curve, clamped to just past the board so a steep branch is cut off
    // at the edge rather than drawn a thousand pixels away.
    let d = ""
    for (let i = 0; i <= 260; i++) {
      const x = -6.5 + (13 * i) / 260
      const y = Math.max(-20, Math.min(380, py(a * x * x + b * x + c)))
      d += `${i ? " L" : "M"} ${px(x).toFixed(1)} ${y.toFixed(1)}`
    }
    svg.append(this.node("path", { d, fill: "none", stroke: "#5048e5", "stroke-width": 4, "stroke-linecap": "round" }))

    // Drawn left to right, whichever of x₁ and x₂ that is.
    const marks = [ ...roots ].sort((p, q) => p - q).map((root) => {
      const visible = Math.abs(root) <= X_MAX + 0.2
      const x = px(Math.max(-X_MAX - 0.2, Math.min(X_MAX + 0.2, root)))
      svg.append(this.node("circle", { cx: x, cy: OY, r: 8, fill: visible ? "#ea580c" : "none", stroke: visible ? "#ffffff" : "#ea580c", "stroke-width": 3 }))
      return { x, text: visible ? copy.root_label.replace("%{x}", rel(root)) : copy.off_screen }
    })
    for (const mark of placeLabels(marks)) {
      const label = this.node("text", { x: mark.left, y: OY + 28 + 20 * mark.row, "font-size": 15, "font-weight": 900, fill: "#9a3412", stroke: "#ffffff", "stroke-width": 4, "paint-order": "stroke" })
      label.textContent = mark.text
      svg.append(label)
    }
    return svg
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
