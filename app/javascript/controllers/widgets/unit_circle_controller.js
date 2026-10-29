import { Controller } from "@hotwired/stimulus"

const SVG = "http://www.w3.org/2000/svg"
const SIZE = 340
const CENTER = SIZE / 2
const RADIUS = 128

// Unit-circle widget: the student picks a point on the circle, sees its angle
// and the two projections — the sine as the height, the cosine as the width —
// and adds the angles the question asks for. {angles: [30, 150]} is the answer
// state, in degrees.
//
// The pegs are real buttons for the keyboard and a screen reader, but at 15°
// they are closer together than a fingertip, so a press anywhere on the board
// picks the nearest peg instead. The ticks at 1/2, √2/2 and √3/2 on both axes
// are the scaffold: the special values are read off the picture, not off a
// number — the numbers are shown only when params.values says the question is
// about where an angle lies rather than what its sine is.
//
// With params.degrees off the question *is* the angle ("отбележи 7π/6"), so the
// page never names one: no readout, a neutral add button, the picked points
// numbered 1, 2, … on the circle and in the chips, and pegs labelled by their
// position for a screen reader rather than by their angle.
export default class extends Controller {
  static targets = ["canvas", "readout", "sine", "cosine", "add", "chips", "hidden"]
  static values = { step: { type: Number, default: 15 }, values: Boolean, degrees: { type: Boolean, default: true }, labels: Object }

  connect() {
    this.selected = null
    this.angles = []
    this.build()
    this.update()
  }

  build() {
    const board = document.createElement("div")
    board.className = "relative aspect-square w-full touch-none select-none"

    const svg = this.svg("svg", { viewBox: `0 0 ${SIZE} ${SIZE}`, class: "absolute inset-0 h-full w-full", "aria-hidden": "true" })
    svg.append(
      this.svg("line", { x1: 8, y1: CENTER, x2: SIZE - 8, y2: CENTER, stroke: "#c5c5d6", "stroke-width": 2 }),
      this.svg("line", { x1: CENTER, y1: 8, x2: CENTER, y2: SIZE - 8, stroke: "#c5c5d6", "stroke-width": 2 }),
      this.svg("circle", { cx: CENTER, cy: CENTER, r: RADIUS, fill: "none", stroke: "#3b3b55", "stroke-width": 3 })
    )
    this.ticks(svg)
    this.quadrantLabels(svg)

    this.arc = this.svg("path", { fill: "none", stroke: "#7f7ff7", "stroke-width": 2.5 })
    this.cosine = this.svg("line", { stroke: "#0d9488", "stroke-width": 5, "stroke-linecap": "round" })
    this.sine = this.svg("line", { stroke: "#ea580c", "stroke-width": 5, "stroke-linecap": "round" })
    this.radius = this.svg("line", { x1: CENTER, y1: CENTER, stroke: "#5048e5", "stroke-width": 4, "stroke-linecap": "round" })
    svg.append(this.arc, this.cosine, this.sine, this.radius)

    board.append(svg)

    this.pegs = new Map()
    for (let angle = 0; angle < 360; angle += this.stepValue) {
      const [x, y] = this.point(angle, RADIUS)
      const button = document.createElement("button")
      button.type = "button"
      button.tabIndex = -1
      button.setAttribute("aria-label", this.degreesValue ? this.label("point", angle) : this.numbered("marker", angle / this.stepValue + 1))
      button.style.left = `${(x / SIZE) * 100}%`
      button.style.top = `${(y / SIZE) * 100}%`
      button.className = "absolute grid size-8 -translate-x-1/2 -translate-y-1/2 place-items-center rounded-full focus-visible:outline-3 focus-visible:outline-primary-300"
      const dot = document.createElement("span")
      dot.className = "block rounded-full transition-transform motion-reduce:transition-none"
      button.append(dot)
      button.addEventListener("click", (event) => {
        event.stopPropagation()
        this.select(angle)
      })
      button.addEventListener("keydown", (event) => this.rotate(event))
      this.pegs.set(angle, button)
      board.append(button)
    }

    board.addEventListener("pointerdown", (event) => {
      if (event.target.closest("button")) return
      const rect = board.getBoundingClientRect()
      const dx = event.clientX - rect.left - rect.width / 2
      const dy = rect.top + rect.height / 2 - event.clientY
      if (Math.hypot(dx, dy) < rect.width * 0.12) return // the centre says nothing about an angle
      const raw = (Math.atan2(dy, dx) * 180) / Math.PI
      this.select(this.snap(raw), { focus: true })
    })

    this.canvasTarget.replaceChildren(board)
  }

  // Ticks at the special values on both axes, labelled on the positive side
  // only and staggered either side of the axis — four labels inside 128 units
  // do not fit on one line.
  ticks(svg) {
    const marks = [ [ 0.5, "1/2", 1 ], [ Math.SQRT2 / 2, "√2/2", -1 ], [ Math.sqrt(3) / 2, "√3/2", 1 ], [ 1, "1", -1 ] ]
    marks.forEach(([ value, text, side ]) => {
      const offset = value * RADIUS
      for (const sign of [ 1, -1 ]) {
        svg.append(this.svg("line", { x1: CENTER + sign * offset, y1: CENTER - 5, x2: CENTER + sign * offset, y2: CENTER + 5, stroke: "#9a9ab0", "stroke-width": 2 }))
        svg.append(this.svg("line", { x1: CENTER - 5, y1: CENTER - sign * offset, x2: CENTER + 5, y2: CENTER - sign * offset, stroke: "#9a9ab0", "stroke-width": 2 }))
      }
      svg.append(this.text(CENTER + offset, CENTER + (side > 0 ? 19 : -10), text, "middle"))
      svg.append(this.text(CENTER + (side > 0 ? -9 : 9), CENTER - offset + 4, text, side > 0 ? "end" : "start"))
    })
  }

  quadrantLabels(svg) {
    [ 0, 90, 180, 270 ].forEach((angle) => {
      const [x, y] = this.point(angle, RADIUS + 24)
      svg.append(this.text(x, y + 4, `${angle}°`, "middle", "#50506b"))
    })
  }

  select(angle, { focus = false } = {}) {
    this.selected = ((angle % 360) + 360) % 360
    this.update()
    if (focus) this.pegs.get(this.selected)?.focus()
  }

  rotate(event) {
    const turns = { ArrowLeft: 1, ArrowUp: 1, ArrowRight: -1, ArrowDown: -1 }
    if (!(event.key in turns)) return
    event.preventDefault()
    this.select((this.selected ?? 0) + turns[event.key] * this.stepValue, { focus: true })
  }

  add() {
    if (this.selected === null || this.angles.includes(this.selected)) return
    this.angles = [ ...this.angles, this.selected ].sort((a, b) => a - b)
    this.update()
  }

  remove(angle) {
    this.angles = this.angles.filter((other) => other !== angle)
    this.update()
  }

  update() {
    const selected = this.selected
    const has = selected !== null

    this.pegs.forEach((button, angle) => {
      const on = angle === selected
      const added = this.angles.includes(angle)
      const marked = added && !this.degreesValue
      button.tabIndex = angle === (selected ?? 0) ? 0 : -1
      button.setAttribute("aria-pressed", on)
      button.firstChild.textContent = marked ? this.angles.indexOf(angle) + 1 : ""
      button.firstChild.className = [
        "grid place-items-center rounded-full text-[10px] leading-none font-black text-white transition-transform motion-reduce:transition-none",
        on ? "size-[18px] bg-primary-600 ring-4 ring-white outline-2 outline-primary-600" :
          marked ? "size-[18px] bg-primary-500" :
            added ? "size-3.5 bg-primary-400" : "size-2.5 bg-ink-400"
      ].join(" ")
    })

    for (const element of [ this.radius, this.sine, this.cosine, this.arc ]) element.setAttribute("visibility", has ? "visible" : "hidden")
    if (has) {
      const [x, y] = this.point(selected, RADIUS)
      this.set(this.radius, { x2: x, y2: y })
      this.set(this.cosine, { x1: CENTER, y1: CENTER, x2: x, y2: CENTER })
      this.set(this.sine, { x1: x, y1: CENTER, x2: x, y2: y })
      const [ax, ay] = this.point(0, 26)
      const [bx, by] = this.point(selected, 26)
      this.arc.setAttribute("d", `M ${ax} ${ay} A 26 26 0 ${selected > 180 ? 1 : 0} 0 ${bx} ${by}`)
    }

    if (this.hasReadoutTarget) this.readoutTarget.textContent = has ? `${selected}°` : "—"
    if (this.valuesValue && this.hasSineTarget) {
      const radians = ((selected ?? 0) * Math.PI) / 180
      this.sineTarget.textContent = has ? this.decimal(Math.sin(radians)) : "—"
      this.cosineTarget.textContent = has ? this.decimal(Math.cos(radians)) : "—"
    }

    this.addTarget.disabled = !has || this.angles.includes(selected)
    this.addTarget.textContent = this.degreesValue ? this.label("add", has ? selected : "…") : this.labelsValue.add_hidden

    this.chipsTarget.replaceChildren(...this.angles.map((angle, index) => {
      const chip = document.createElement("button")
      chip.type = "button"
      chip.className = "min-h-11 rounded-[12px] bg-primary-100 px-3 text-base font-black text-primary-800"
      chip.textContent = this.degreesValue ? `${angle}° ×` : `${this.numbered("marker", index + 1)} ×`
      chip.setAttribute("aria-label", this.degreesValue ? this.label("remove", angle) : this.numbered("remove_marker", index + 1))
      chip.addEventListener("click", () => this.remove(angle))
      return chip
    }))

    this.hiddenTarget.value = this.angles.length ? JSON.stringify({ angles: this.angles }) : ""
  }

  snap(degrees) {
    return Math.round((((degrees % 360) + 360) % 360) / this.stepValue) * this.stepValue % 360
  }

  // Two decimals, a decimal comma and a real minus — and no "−0,00" for the
  // cosine of 90°, which floating point puts a hair below zero.
  decimal(value) {
    const rounded = Math.round(value * 100) / 100
    const text = Math.abs(rounded).toFixed(2).replace(".", ",")
    return rounded < 0 ? `−${text}` : text
  }

  point(degrees, radius) {
    const radians = (degrees * Math.PI) / 180
    return [ CENTER + radius * Math.cos(radians), CENTER - radius * Math.sin(radians) ]
  }

  label(key, angle) {
    return String(this.labelsValue[key] || "").replace("%{angle}", angle)
  }

  numbered(key, number) {
    return String(this.labelsValue[key] || "%{number}").replace("%{number}", number)
  }

  text(x, y, content, anchor, fill = "#666680") {
    const text = this.svg("text", { x, y, fill, "font-size": 11, "font-weight": 800, "text-anchor": anchor })
    text.textContent = content
    return text
  }

  set(element, attributes) {
    Object.entries(attributes).forEach(([key, value]) => element.setAttribute(key, value))
  }

  svg(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    this.set(element, attributes)
    return element
  }
}
