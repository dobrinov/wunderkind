import { Controller } from "@hotwired/stimulus"

// Geoboard widget: a square board of pegs; the student taps corners in order
// and closes the shape by tapping the first peg again. {points: [[col, row]]}
// is the answer state, set only once the polygon is closed — an open path is
// not a shape and has no area to grade.
//
// The pegs are buttons, so Tab and Space reach them; the arrow keys move along
// the board from whichever peg has focus. Enter is left alone: the answer form
// claims it to submit.
export default class extends Controller {
  static targets = ["board", "readout", "hidden"]
  static values = { size: { type: Number, default: 7 }, labels: Object }

  connect() {
    this.points = []
    this.closed = false
    this.build()
    this.update()
  }

  build() {
    const n = this.sizeValue
    this.boardTarget.style.maxWidth = `${n * 52}px`
    this.boardTarget.style.aspectRatio = "1 / 1"
    this.boardTarget.classList.add("mx-auto", "rounded-[14px]", "bg-ink-50", "ring-2", "ring-ink-200")

    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("viewBox", "0 0 100 100")
    svg.setAttribute("aria-hidden", "true")
    svg.setAttribute("class", "pointer-events-none absolute inset-0 h-full w-full")
    this.shape = document.createElementNS("http://www.w3.org/2000/svg", "polygon")
    this.shape.setAttribute("class", "fill-primary-400/20")
    this.path = document.createElementNS("http://www.w3.org/2000/svg", "polyline")
    this.path.setAttribute("fill", "none")
    this.path.setAttribute("class", "stroke-primary-600")
    this.path.setAttribute("stroke-width", "1.4")
    this.path.setAttribute("stroke-linejoin", "round")
    this.path.setAttribute("stroke-linecap", "round")
    svg.append(this.shape, this.path)

    this.pegs = new Map()
    const pegs = []
    for (let row = 0; row < n; row++) {
      for (let col = 0; col < n; col++) {
        const peg = document.createElement("button")
        peg.type = "button"
        peg.dataset.col = col
        peg.dataset.row = row
        peg.className = "group absolute grid -translate-x-1/2 -translate-y-1/2 place-items-center rounded-full focus-visible:outline-3 focus-visible:outline-primary-300"
        peg.style.left = `${this.at(col)}%`
        peg.style.top = `${this.at(row)}%`
        // Pegs sit 100/n % apart; a button no wider than that keeps neighbours
        // from overlapping, which on a 9×9 phone board sent a tap a little
        // right of a dot to the next peg.
        peg.style.width = peg.style.height = `min(2.75rem, ${100 / n}%)`
        const dot = document.createElement("span")
        dot.className = "block rounded-full transition-transform motion-reduce:transition-none group-hover:scale-125"
        peg.append(dot)
        peg.addEventListener("click", () => this.tap(col, row))
        peg.addEventListener("keydown", (event) => this.nudge(event, col, row))
        this.pegs.set(`${col},${row}`, peg)
        pegs.push(peg)
      }
    }

    this.boardTarget.replaceChildren(svg, ...pegs)
  }

  // Pegs sit inside a margin so the outer ones are not clipped by the board.
  at(index) {
    const margin = 50 / this.sizeValue
    return margin + (index * (100 - 2 * margin)) / (this.sizeValue - 1)
  }

  tap(col, row) {
    if (this.closed) return

    const first = this.points[0]
    if (this.points.length >= 3 && first[0] === col && first[1] === row) {
      this.closed = true
    } else if (!this.points.some(([c, r]) => c === col && r === row) && !this.foldsBack(col, row)) {
      this.points.push([col, row])
    }
    this.update()
  }

  // A peg straight back along the side just drawn would fold that side over
  // itself — a spike the grader refuses, so it is not offered here either.
  foldsBack(col, row) {
    if (this.points.length < 2) return false

    const [a, b] = this.points.slice(-2)
    const cross = (b[0] - a[0]) * (row - b[1]) - (b[1] - a[1]) * (col - b[0])
    const dot = (a[0] - b[0]) * (col - b[0]) + (a[1] - b[1]) * (row - b[1])
    return cross === 0 && dot > 0
  }

  nudge(event, col, row) {
    const moves = { ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1] }
    const move = moves[event.key]
    if (!move) return

    event.preventDefault()
    const n = this.sizeValue
    const target = this.pegs.get(`${Math.min(n - 1, Math.max(0, col + move[0]))},${Math.min(n - 1, Math.max(0, row + move[1]))}`)
    target?.focus()
  }

  undo() {
    if (this.closed) this.closed = false
    else this.points.pop()
    this.update()
  }

  reset() {
    this.points = []
    this.closed = false
    this.update()
  }

  update() {
    const coords = this.points.map(([c, r]) => `${this.at(c)},${this.at(r)}`)
    this.path.setAttribute("points", (this.closed ? [...coords, coords[0]] : coords).join(" "))
    this.shape.setAttribute("points", this.closed ? coords.join(" ") : "")

    const closable = !this.closed && this.points.length >= 3
    this.pegs.forEach((peg, key) => {
      const [col, row] = key.split(",").map(Number)
      const index = this.points.findIndex(([c, r]) => c === col && r === row)
      const first = index === 0 && closable
      const dot = peg.firstChild
      dot.className = [
        "block rounded-full transition-transform motion-reduce:transition-none group-hover:scale-125",
        index >= 0 ? "size-4 bg-primary-600" : "size-2.5 bg-ink-400",
        first ? "ring-4 ring-reward-400 ring-offset-2" : ""
      ].join(" ")
      let label = this.labelsValue.peg.replace("%{column}", col + 1).replace("%{row}", row + 1)
      if (first) label += ` — ${this.labelsValue.close}`
      peg.setAttribute("aria-label", label)
      peg.setAttribute("aria-pressed", index >= 0)
    })

    const facts = this.closed ? this.facts() : null
    this.readoutTarget.replaceChildren(
      this.stat(this.labelsValue.corners, String(this.points.length)),
      this.stat(this.labelsValue.area, facts ? this.number(facts.area) : "—"),
      this.stat(this.labelsValue.perimeter, facts ? this.number(facts.perimeter) : "—")
    )
    this.hiddenTarget.value = this.closed ? JSON.stringify({ points: this.points }) : ""
  }

  facts() {
    let twice = 0
    let perimeter = 0
    this.points.forEach(([x1, y1], i) => {
      const [x2, y2] = this.points[(i + 1) % this.points.length]
      twice += x1 * y2 - x2 * y1
      perimeter += Math.hypot(x2 - x1, y2 - y1)
    })
    return { area: Math.abs(twice) / 2, perimeter }
  }

  number(value) {
    const rounded = Math.round(value * 100) / 100
    const text = rounded.toLocaleString("bg-BG", { maximumFractionDigits: 2 })
    return Math.abs(rounded - value) > 1e-9 ? `≈ ${text}` : text
  }

  stat(label, value) {
    const box = document.createElement("div")
    box.className = "flex flex-col rounded-[12px] bg-ink-50 px-3 py-2"
    const name = document.createElement("span")
    name.className = "text-[11.5px] font-black uppercase tracking-[.05em] text-ink-500"
    name.textContent = label
    const number = document.createElement("span")
    number.className = "text-xl font-black text-primary-700"
    number.textContent = value
    box.append(name, number)
    return box
  }
}
