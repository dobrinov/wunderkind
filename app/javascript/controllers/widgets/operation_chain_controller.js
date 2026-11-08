import { Controller } from "@hotwired/stimulus"

// Operation-chain widget: the first-grade puzzle where two numbers joined by a
// sign give the number their arrows point to, and that number joined with a
// third gives the last one. Five squares in a fixed shape —
//
//     tl  op0  tr
//         m   op1  r
//             b
//
// — tl op0 tr = m, then m op1 r = b. A worked example is drawn first, in a
// dashed frame, then each chain to fill with the number tiles it may use. The
// empty squares are the answer boxes: the child writes straight into the
// picture. It replaced a picture with a paragraph describing its arrows, which
// a student reported as impossible to follow.
//
// {values: {"<chain>.<place>": text}} is the answer state, submitted once every
// box has something in it.
const PLACES = { tl: [ 0, 0 ], tr: [ 2, 0 ], m: [ 1, 1 ], r: [ 3, 1 ], b: [ 2, 2 ] }
const OPS = [ [ 1, 0 ], [ 2, 1 ] ]
const ARROWS = [ [ "tl", "m" ], [ "tr", "m" ], [ "m", "b" ], [ "r", "b" ] ]
const SQUARE = 44
const STEP_X = 52
const STEP_Y = 72
const SVG = "http://www.w3.org/2000/svg"

export default class extends Controller {
  static targets = ["board", "hidden"]
  static values = { example: Object, chains: Array, labels: Object }

  connect() {
    this.values = {}
    this.render()
  }

  render() {
    const blocks = []
    if (this.exampleValue.cells) blocks.push(this.chain(this.exampleValue, null))
    this.chainsValue.forEach((chain, index) => blocks.push(this.chain(chain, index)))
    this.boardTarget.replaceChildren(...blocks)

    this.blanks = this.chainsValue.flatMap((chain, index) =>
      Object.keys(PLACES).filter((place) => chain.cells?.[place] == null).map((place) => `${index}.${place}`)
    )
    this.sync()
  }

  chain(chain, index) {
    const block = document.createElement("div")
    block.className = index === null ?
      "flex flex-col items-center gap-2 rounded-lg border-2 border-dashed border-ink-300 p-3" :
      "flex flex-col items-center gap-2 p-3"

    const head = document.createElement("div")
    head.className = "flex items-center gap-1"
    if (index === null) {
      const label = document.createElement("span")
      label.className = "mr-1 text-sm font-bold text-muted"
      label.textContent = this.labelsValue.example
      head.append(label)
    }
    ;(chain.tiles || []).forEach((tile) => {
      const chip = document.createElement("span")
      chip.className = "grid h-8 w-7 place-items-center rounded-md border-2 border-amber-400 bg-amber-50 text-base font-black text-ink-800"
      chip.textContent = tile
      head.append(chip)
    })
    block.append(head)

    const width = (3 * STEP_X) + SQUARE
    const height = (2 * STEP_Y) + SQUARE
    const figure = document.createElement("div")
    figure.className = "relative"
    figure.style.width = `${width}px`
    figure.style.height = `${height}px`
    figure.append(this.arrows(width, height))

    Object.entries(PLACES).forEach(([ place, [ col, row ] ]) => {
      const value = chain.cells?.[place]
      const box = document.createElement("div")
      box.className = "absolute grid place-items-center overflow-hidden rounded-md border-2 border-primary-600 " +
        (value == null ? "bg-primary-50" : "bg-white")
      box.style.left = `${col * STEP_X}px`
      box.style.top = `${row * STEP_Y}px`
      box.style.width = `${SQUARE}px`
      box.style.height = `${SQUARE}px`

      if (value == null && index !== null) {
        const key = `${index}.${place}`
        const input = document.createElement("input")
        input.type = "text"
        input.inputMode = "numeric"
        input.autocomplete = "off"
        input.setAttribute("aria-label", this.labelsValue.label
          .replace("%{chain}", index + 1).replace("%{place}", this.labelsValue.places?.[place] ?? place))
        input.className = "size-full min-w-0 bg-transparent text-center text-xl font-black text-ink-800 outline-0 focus:bg-white focus:ring-2 focus:ring-inset focus:ring-primary-500"
        input.value = this.values[key] ?? ""
        input.addEventListener("input", (event) => this.update(key, event.target.value))
        box.append(input)
      } else {
        const span = document.createElement("span")
        span.className = "text-xl font-black text-ink-800"
        span.textContent = value ?? ""
        box.append(span)
      }
      figure.append(box)
    })

    ;(chain.ops || []).forEach((op, i) => {
      const [ col, row ] = OPS[i]
      const sign = document.createElement("span")
      sign.className = "absolute grid place-items-center text-2xl font-black text-ink-800"
      sign.setAttribute("aria-hidden", "true")
      sign.style.left = `${col * STEP_X}px`
      sign.style.top = `${row * STEP_Y}px`
      sign.style.width = `${SQUARE}px`
      sign.style.height = `${SQUARE}px`
      sign.textContent = op
      figure.append(sign)
    })

    block.append(figure)
    return block
  }

  arrows(width, height) {
    const svg = document.createElementNS(SVG, "svg")
    svg.setAttribute("width", width)
    svg.setAttribute("height", height)
    svg.setAttribute("aria-hidden", "true")
    svg.setAttribute("class", "absolute inset-0 text-ink-700")

    const defs = document.createElementNS(SVG, "defs")
    const marker = document.createElementNS(SVG, "marker")
    const id = `chain-arrow-${Math.random().toString(36).slice(2)}`
    Object.entries({ id, viewBox: "0 0 8 8", refX: 7, refY: 4, markerWidth: 7, markerHeight: 7, orient: "auto" })
      .forEach(([ name, value ]) => marker.setAttribute(name, value))
    const head = document.createElementNS(SVG, "path")
    head.setAttribute("d", "M0 0 L8 4 L0 8 z")
    head.setAttribute("fill", "currentColor")
    marker.append(head)
    defs.append(marker)
    svg.append(defs)

    const centre = (place) => {
      const [ col, row ] = PLACES[place]
      return [ (col * STEP_X) + (SQUARE / 2), (row * STEP_Y) + (SQUARE / 2) ]
    }
    ARROWS.forEach(([ from, to ]) => {
      const [ x1, y1 ] = centre(from)
      const [ x2, y2 ] = centre(to)
      // From the bottom edge of one square to the top edge of the next.
      const t1 = (SQUARE / 2 + 2) / (y2 - y1)
      const t2 = (SQUARE / 2 + 3) / (y2 - y1)
      const line = document.createElementNS(SVG, "line")
      Object.entries({
        x1: x1 + ((x2 - x1) * t1), y1: y1 + ((y2 - y1) * t1),
        x2: x2 - ((x2 - x1) * t2), y2: y2 - ((y2 - y1) * t2),
        stroke: "currentColor", "stroke-width": 2, "marker-end": `url(#${id})`
      }).forEach(([ name, value ]) => line.setAttribute(name, value))
      svg.append(line)
    })
    return svg
  }

  update(key, value) {
    this.values[key] = value
    this.sync()
  }

  sync() {
    const complete = this.blanks.every((key) => (this.values[key] ?? "").trim() !== "")
    this.hiddenTarget.value = complete ? JSON.stringify({ values: this.values }) : ""
  }
}
