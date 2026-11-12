import { Controller } from "@hotwired/stimulus"

// „Системи уравнения": a system of two linear equations drawn as the two
// lines y = k₁x + n₁ and y = k₂x + n₂. The point where they cross is the
// one pair (x; y) that satisfies both, so the solution is read off the
// picture and then worked by setting the two right-hand sides equal; equal
// slopes give the two cases a system can fail in — parallel lines (no
// solution) and the same line twice (infinitely many). Each equation is also
// shown as school writes a system, with x and y on one side. The grid is
// square, so a slope of 1 looks like 45°, and only 360 units wide, so its
// text is still readable on a phone.
const SVG = "http://www.w3.org/2000/svg"
const OX = 180, OY = 129, UNIT = 17 // origin and px per unit on the board
const X_MAX = 10, Y_MAX = 7
const WIDTH = 360, CHAR = 9.5 // the board's width, and a generous width per character of a label
// A pale halo, the colour of the figure's ground, behind every label.
const HALO = { stroke: "#f5f5fa", "stroke-width": 5, "stroke-linejoin": "round", "paint-order": "stroke" }
const COLOURS = ["#5048e5", "#312e81"]

const gcd = (a, b) => (b ? gcd(b, a % b) : a)
// A line never ends on a lone sign: every =, ≈, ·, :, ÷, + or − that stands
// between spaces is tied to what follows it with a non-breaking space.
const tie = (text) => text.replace(/(?<=\s)([=≈·:÷+−<>≤≥]) /g, "$1\u00A0")
// A whole number with a real minus.
const num = (value) => (value < 0 ? "−" : "") + Math.abs(value)

// top/bottom in lowest terms: "3", "−5/2".
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

// kx + n as it is written: "−x + 5", "2x − 1", "3", "0".
const side = (k, n) => (term(k, "x", true) + term(n, "", k === 0)) || "0"

// The same line as a school system writes it, x and y on the left with a
// positive coefficient before x: "x + y = 5", "2x − y = 1", "y = 3".
function school(k, n) {
  if (k === 0) return `y = ${num(n)}`
  const x = (Math.abs(k) === 1 ? "" : Math.abs(k)) + "x"
  return k > 0 ? `${x} − y = ${num(-n)}` : `${x} + y = ${num(n)}`
}

export default class extends Controller {
  static targets = ["k1", "n1", "k2", "n2", "k1Out", "n1Out", "k2Out", "n2Out", "school1", "school2", "slope1", "slope2", "figure", "verdict", "work"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const k1 = Number(this.k1Target.value), n1 = Number(this.n1Target.value)
    const k2 = Number(this.k2Target.value), n2 = Number(this.n2Target.value)

    this.k1OutTarget.textContent = num(k1)
    this.n1OutTarget.textContent = num(n1)
    this.k2OutTarget.textContent = num(k2)
    this.n2OutTarget.textContent = num(n2)
    this.school1Target.textContent = tie(school(k1, n1))
    this.school2Target.textContent = tie(school(k2, n2))
    // A horizontal line is already written as y = n, so it is not said twice.
    this.slope1Target.textContent = k1 === 0 ? "" : copy.slope_form.replaceAll("%{line}", tie(`y = ${side(k1, n1)}`))
    this.slope2Target.textContent = k2 === 0 ? "" : copy.slope_form.replaceAll("%{line}", tie(`y = ${side(k2, n2)}`))

    const kind = k1 !== k2 ? "one" : n1 !== n2 ? "none" : "all"
    let point = null
    let fill = (text) => tie(text).replaceAll("%{k}", num(k1))
    if (kind === "one") {
      // k₁x + n₁ = k₂x + n₂ gives x = (n₂ − n₁)/(k₁ − k₂), and y follows.
      const bottom = k1 - k2
      const x = fraction(n2 - n1, bottom), y = fraction(k1 * n2 - k2 * n1, bottom)
      point = { x: (n2 - n1) / bottom, y: (k1 * n2 - k2 * n1) / bottom, text: copy.point_label.replaceAll("%{x}", x).replaceAll("%{y}", y) }
      point.visible = Math.abs(point.y) <= Y_MAX
      fill = (text) => tie(text).replaceAll("%{x}", x).replaceAll("%{y}", y)
        .replaceAll("%{first}", tie(side(k1, n1))).replaceAll("%{second}", tie(side(k2, n2)))
    }

    this.verdictTarget.textContent = fill(copy[`verdict_${kind}`])
    this.workTarget.textContent = fill(copy[`work_${kind}`]) + (point && !point.visible ? ` ${copy.off_screen}` : "")
    this.figureTarget.replaceChildren(this.graph([[k1, n1], [k2, n2]], point, fill(copy[`figure_${kind}`])))
  }

  graph(lines, point, label) {
    const px = (x) => OX + x * UNIT
    const py = (y) => OY - y * UNIT
    const svg = this.node("svg", { viewBox: "0 0 360 258", class: "w-full max-w-[460px]", role: "img" })
    svg.setAttribute("aria-label", label)

    for (let x = -X_MAX; x <= X_MAX; x++) {
      svg.append(this.node("line", { x1: px(x), y1: py(Y_MAX), x2: px(x), y2: py(-Y_MAX), stroke: x === 0 ? "#9a9ab0" : "#e2e2ec", "stroke-width": x === 0 ? 2 : 1 }))
    }
    for (let y = -Y_MAX; y <= Y_MAX; y++) {
      svg.append(this.node("line", { x1: px(-X_MAX), y1: py(y), x2: px(X_MAX), y2: py(y), stroke: y === 0 ? "#9a9ab0" : "#e2e2ec", "stroke-width": y === 0 ? 2 : 1 }))
    }

    // Each line is cut to the board: the stretch of x for which y is on it.
    // The first is drawn wide and the second narrow on top, so two equal
    // lines are seen to be two.
    lines.forEach(([k, n], index) => {
      let from = -X_MAX, to = X_MAX
      if (k !== 0) {
        const ends = [(-Y_MAX - n) / k, (Y_MAX - n) / k].sort((p, q) => p - q)
        from = Math.max(from, ends[0])
        to = Math.min(to, ends[1])
      }
      svg.append(this.node("line", {
        x1: px(from), y1: py(k * from + n), x2: px(to), y2: py(k * to + n),
        stroke: COLOURS[index], "stroke-width": index === 0 ? 5 : 2.5, "stroke-linecap": "round"
      }))
    })

    // The point's label goes above its point, or under it when there is no
    // room above, slid inwards so it stays on the board.
    let taken = null
    if (point && point.visible) {
      const width = point.text.length * CHAR
      const left = Math.max(4, Math.min(WIDTH - 4 - width, px(point.x) - width / 2))
      const y = py(point.y) - 14 < 20 ? py(point.y) + 26 : py(point.y) - 14
      taken = { left: left - 4, right: left + width + 4, top: Math.min(y - 16, py(point.y) - 10), bottom: Math.max(y + 5, py(point.y) + 10) }
      svg.append(this.node("circle", { cx: px(point.x), cy: py(point.y), r: 6, fill: "#ffffff", stroke: "#312e81", "stroke-width": 3 }))
      svg.append(this.text(point.text, { x: left + width / 2, y, "text-anchor": "middle", "font-size": 15, "font-weight": 900, fill: "#312e81", ...HALO }))
    }

    // The axes' letters and the two unit marks, drawn over the lines with a
    // pale halo so a line behind one does not strike it through — and left
    // out where the point and its label need the room.
    const marks = [
      { text: "x", x: px(X_MAX) - 2, y: OY + 17, anchor: "end" },
      { text: "y", x: OX + 7, y: py(Y_MAX) + 13, anchor: "start" },
      { text: "1", x: px(1), y: OY + 17, anchor: "middle" },
      { text: "1", x: OX - 6, y: py(1) + 5, anchor: "end" }
    ]
    for (const mark of marks) {
      const left = mark.anchor === "end" ? mark.x - 10 : mark.anchor === "middle" ? mark.x - 5 : mark.x
      if (taken && left < taken.right && left + 10 > taken.left && mark.y - 13 < taken.bottom && mark.y + 3 > taken.top) continue
      svg.append(this.text(mark.text, { x: mark.x, y: mark.y, "text-anchor": mark.anchor, "font-size": 14, "font-weight": 900, fill: "#50506b", ...HALO }))
    }
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
