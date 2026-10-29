import { Controller } from "@hotwired/stimulus"

// Equal-parts widget: a figure with one segment or angle highlighted, and the
// student taps every part the construction makes equal to it — the other half
// a perpendicular bisector cuts, the two halves of a bisected angle, the
// angles a transversal makes equal. {parts: [id, ...]} is the answer state.
//
// The figure is drawn from the points it is given and never measures anything:
// equal parts must be found by reasoning, and the problem files draw at least
// one decoy that looks as long as the given part but is not. Each part is
// tappable on the figure and also listed as a named button below it, so the
// widget works from a keyboard and a screen reader as well as a finger.
const SVG = "http://www.w3.org/2000/svg"
const ARC = 9 // radius of an angle's wedge, in board units (the board is 100 wide)

export default class extends Controller {
  static targets = ["figure", "chips", "readout", "hidden"]
  static values = { points: Object, segments: Array, angles: Array, lines: Array, given: String, labels: Object }

  connect() {
    this.picked = new Set()
    this.parts = [
      ...this.segmentsValue.map((segment) => ({ ...segment, kind: "segment", name: `${segment.from}${segment.to}` })),
      ...this.anglesValue.map((angle) => ({ ...angle, kind: "angle", name: `∠${angle.from}${angle.vertex}${angle.to}` }))
    ]
    // Only parts of the given one's kind are offered: an angle question still
    // draws the triangle's sides, but they are the figure, not choices.
    const given = this.parts.find((part) => part.id === this.givenValue)
    this.kind = given ? given.kind : "segment"
    this.render()
  }

  render() {
    this.renderFigure()
    this.renderChips()
    const names = this.parts.filter((part) => this.picked.has(part.id)).map((part) => part.name)
    this.readoutTarget.textContent = `${this.labelsValue.picked}: ${names.length ? names.join(", ") : this.labelsValue.none}`
    this.hiddenTarget.value = this.picked.size ? JSON.stringify({ parts: [...this.picked] }) : ""
  }

  toggle(id) {
    if (id === this.givenValue) return
    this.picked.has(id) ? this.picked.delete(id) : this.picked.add(id)
    this.render()
  }

  // --- the figure ----------------------------------------------------------

  renderFigure() {
    const svg = this.element.ownerDocument.createElementNS(SVG, "svg")
    svg.setAttribute("viewBox", "-8 -8 116 116")
    svg.setAttribute("class", "w-full select-none")
    svg.setAttribute("aria-hidden", "true") // the chips below carry the parts for assistive tech

    // The kind that is not being asked about goes underneath and never takes a
    // tap: an angle question's sides used to lie over every narrow wedge.
    const segments = this.parts.filter((p) => p.kind === "segment").map((part) => this.segmentLine(part))
    const angles = this.angleRadii()
      .sort((a, b) => b.size - a.size) // larger first, so a smaller wedge inside it stays on top
      .map(({ part, radius }) => this.angleWedge(part, radius))

    for (const line of this.linesValue) svg.append(this.constructionLine(line))
    if (this.kind === "angle") svg.append(...segments, ...angles)
    else svg.append(...angles, ...segments)
    for (const [name, point] of Object.entries(this.pointsValue)) svg.append(...this.pointMark(name, point))

    this.figureTarget.replaceChildren(svg)
  }

  look(part) {
    if (part.id === this.givenValue) return { stroke: "#d97706", fill: "rgb(251 191 36 / .45)", width: 2.6 }
    if (this.picked.has(part.id)) return { stroke: "#5048e5", fill: "rgb(127 127 247 / .4)", width: 2.6 }
    return { stroke: "#17162b", fill: "rgb(23 22 43 / .04)", width: 1.3 }
  }

  segmentLine(part) {
    const [x1, y1] = this.pointsValue[part.from]
    const [x2, y2] = this.pointsValue[part.to]
    const group = this.node("g")
    const look = this.look(part)
    group.append(
      this.node("line", { x1, y1, x2, y2, stroke: look.stroke, "stroke-width": look.width, "stroke-linecap": "round", "pointer-events": "none" }),
      // A wide transparent line on top is what a finger actually hits.
      this.hit(this.node("line", { x1, y1, x2, y2, stroke: "transparent", "stroke-width": 7, "stroke-linecap": "round" }), part)
    )
    return group
  }

  // Angles at one vertex often contain each other (∠ACB holds ∠ACM and
  // ∠MCB), and drawn at one radius the inner wedges cover the outer one
  // completely. Each larger angle at a vertex gets a larger radius, so a band
  // of it always shows beyond the smaller ones and can be tapped.
  angleRadii() {
    const sized = this.parts.filter((p) => p.kind === "angle").map((part) => ({ part, size: this.angleSize(part) }))
    return sized.map((entry) => {
      const rank = sized.filter((other) => other.part.vertex === entry.part.vertex && other.size < entry.size - 0.5).length
      return { ...entry, radius: ARC + rank * 5 }
    })
  }

  angleSize(part) {
    const [vx, vy] = this.pointsValue[part.vertex]
    const [ax, ay] = this.pointsValue[part.from]
    const [bx, by] = this.pointsValue[part.to]
    const dot = (ax - vx) * (bx - vx) + (ay - vy) * (by - vy)
    const lengths = Math.hypot(ax - vx, ay - vy) * Math.hypot(bx - vx, by - vy) || 1
    return (Math.acos(Math.max(-1, Math.min(1, dot / lengths))) * 180) / Math.PI
  }

  angleWedge(part, radius = ARC) {
    const [vx, vy] = this.pointsValue[part.vertex]
    const [ax, ay] = this.pointsValue[part.from]
    const [bx, by] = this.pointsValue[part.to]
    const unit = (x, y) => { const length = Math.hypot(x, y) || 1; return [x / length, y / length] }
    const [ux, uy] = unit(ax - vx, ay - vy)
    const [wx, wy] = unit(bx - vx, by - vy)
    // Positive cross product in screen coordinates (y down) turns clockwise,
    // which is SVG's sweep-flag 1; the smaller of the two angles is the one meant.
    const sweep = ux * wy - uy * wx > 0 ? 1 : 0
    const r = radius
    const d = `M ${vx} ${vy} L ${vx + ux * r} ${vy + uy * r} A ${r} ${r} 0 0 ${sweep} ${vx + wx * r} ${vy + wy * r} Z`
    const look = this.look(part)
    return this.hit(this.node("path", { d, fill: look.fill, stroke: look.stroke, "stroke-width": look.width === 1.3 ? 0.8 : 1.6 }), part)
  }

  constructionLine(line) {
    const [x1, y1] = this.pointsValue[line.from]
    const [x2, y2] = this.pointsValue[line.to]
    // Construction lines run a little past their points, as drawn by hand.
    const [dx, dy] = [x2 - x1, y2 - y1]
    const reach = 0.25
    const group = this.node("g")
    group.append(this.node("line", {
      x1: x1 - dx * reach, y1: y1 - dy * reach, x2: x2 + dx * reach, y2: y2 + dy * reach,
      stroke: "#9a9ab0", "stroke-width": 1, "stroke-dasharray": "3 2.5", "pointer-events": "none"
    }))
    if (line.label) {
      const label = this.node("text", { x: x2 + dx * reach + 1.5, y: y2 + dy * reach, "font-size": 5.5, "font-weight": 800, fill: "#666680" })
      label.textContent = line.label
      group.append(label)
    }
    return group
  }

  pointMark(name, [x, y]) {
    // The letter goes on the side away from the middle of the figure, where
    // it is least likely to sit on a line.
    const all = Object.values(this.pointsValue)
    const cx = all.reduce((sum, [px]) => sum + px, 0) / all.length
    const cy = all.reduce((sum, [, py]) => sum + py, 0) / all.length
    const length = Math.hypot(x - cx, y - cy) || 1
    const label = this.node("text", {
      x: x + ((x - cx) / length) * 6, y: y + ((y - cy) / length) * 6 + 2,
      "text-anchor": "middle", "font-size": 6.5, "font-weight": 900, fill: "#17162b", "pointer-events": "none"
    })
    label.textContent = name
    return [this.node("circle", { cx: x, cy: y, r: 1.6, fill: "#17162b", "pointer-events": "none" }), label]
  }

  hit(element, part) {
    if (part.kind !== this.kind) {
      element.setAttribute("pointer-events", "none")
      return element
    }
    if (part.id === this.givenValue) return element
    element.style.cursor = "pointer"
    element.addEventListener("click", () => this.toggle(part.id))
    return element
  }

  node(tag, attributes = {}) {
    const element = this.element.ownerDocument.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }

  // --- the named buttons ---------------------------------------------------

  renderChips() {
    const focused = this.chipsTarget.contains(document.activeElement) ? document.activeElement.dataset.part : null
    this.chipsTarget.replaceChildren(...this.parts.filter((part) => part.kind === this.kind).map((part) => this.chip(part)))
    if (focused) this.chipsTarget.querySelector(`[data-part="${CSS.escape(focused)}"]`)?.focus()
  }

  chip(part) {
    const given = part.id === this.givenValue
    const picked = this.picked.has(part.id)
    const button = document.createElement("button")
    button.type = "button"
    button.dataset.part = part.id
    button.textContent = given ? `${part.name} · ${this.labelsValue.given}` : part.name
    button.disabled = given
    button.setAttribute("aria-pressed", picked)
    button.className = [
      "min-h-11 min-w-11 rounded-[12px] border-2 px-3 text-[15px] font-black transition-colors",
      given ? "border-reward-400 bg-reward-50 text-reward-800"
        : picked ? "border-primary-500 bg-primary-50 text-primary-800 shadow-[var(--edge-selected)]"
          : "border-[var(--color-border)] bg-[var(--color-surface)] text-ink-800 shadow-[var(--edge-control)] hover:border-primary-300"
    ].join(" ")
    if (!given) button.addEventListener("click", () => this.toggle(part.id))
    return button
  }
}
