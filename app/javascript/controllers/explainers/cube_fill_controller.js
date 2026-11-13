import { Controller } from "@hotwired/stimulus"

// „Какво е обем": a box a × b × c filled with unit cubes a layer at a time.
// One layer is the bottom covered — a · b cubes — and the box takes c such
// layers, so the count is a · b · c; the formula is the counting, done once.
// Drawn in an oblique projection (the front true, depth going up and to the
// right, shortened), the empty box as a frame with its hidden edges dashed.
const SVG = "http://www.w3.org/2000/svg"
const WIDTH = 440, HEIGHT = 336, BASE_Y = 296
const UNIT = 40, DEPTH = [20, -14]

export default class extends Controller {
  static targets = ["a", "b", "c", "layers", "aOut", "bOut", "cOut", "layersOut", "figure", "layer", "filled", "total", "note"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const [a, b, c] = [this.aTarget, this.bTarget, this.cTarget].map((input) => Number(input.value))
    // The layer slider never runs past the box's height.
    this.layersTarget.max = c
    const layers = Math.min(Number(this.layersTarget.value), c)
    this.layersTarget.value = layers

    const fill = (text) => text.replaceAll("%{ab}", a * b).replaceAll("%{a}", a).replaceAll("%{b}", b).replaceAll("%{c}", c)
      .replaceAll("%{layers}", layers).replaceAll("%{filled}", layers * a * b).replaceAll("%{v}", a * b * c)

    this.aOutTarget.textContent = a
    this.bOutTarget.textContent = b
    this.cOutTarget.textContent = c
    this.layersOutTarget.textContent = layers
    this.layerTarget.textContent = fill(copy.layer)
    this.filledTarget.textContent = fill(copy.filled)
    this.totalTarget.textContent = fill(copy.total)
    // „1 кубче", not „1 кубчета".
    const one = a * b === 1 ? "_one" : ""
    this.noteTarget.textContent = fill(layers === 0 ? copy[`note_empty${one}`] : layers < c ? copy[`note_part${one}`] : copy.note_full)
    this.figureTarget.replaceChildren(this.box(a, b, c, layers, fill(copy.figure)))
  }

  box(a, b, c, layers, label) {
    const svg = this.node("svg", { viewBox: `0 0 ${WIDTH} ${HEIGHT}`, class: "w-full max-w-[440px]", role: "img" })
    svg.setAttribute("aria-label", label)

    // The front bottom left corner, placed so the whole box is centred.
    const left = (WIDTH - (a * UNIT + b * DEPTH[0])) / 2
    // The corner x cubes along, y cubes back and z cubes up, on the page.
    const at = (x, y, z) => [left + x * UNIT + y * DEPTH[0], BASE_Y - z * UNIT + y * DEPTH[1]]
    const face = (corners, fill, stroke = "#5048e5") =>
      svg.append(this.node("path", { d: `M ${corners.map((corner) => corner.join(" ")).join(" L ")} Z`, fill, stroke, "stroke-width": 1.5, "stroke-linejoin": "round" }))
    const edge = (from, to, dashed) =>
      svg.append(this.node("line", { x1: from[0], y1: from[1], x2: to[0], y2: to[1], stroke: "#9a9ab0", "stroke-width": 2, "stroke-linecap": "round", ...(dashed ? { "stroke-dasharray": "5 5" } : {}) }))

    // The bottom of the box, ruled into the squares a layer stands on.
    for (let x = 0; x < a; x++) {
      for (let y = 0; y < b; y++) face([at(x, y, 0), at(x + 1, y, 0), at(x + 1, y + 1, 0), at(x, y + 1, 0)], "#ececf4", "#c5c5d6")
    }

    // The empty box: three hidden edges dashed, the other nine solid. The
    // cubes are drawn over it, so the frame shows only above them.
    edge(at(0, b, 0), at(a, b, 0), true)
    edge(at(0, b, 0), at(0, b, c), true)
    edge(at(0, 0, 0), at(0, b, 0), true)
    for (const [from, to] of [
      [[0, 0, 0], [a, 0, 0]], [[a, 0, 0], [a, b, 0]], [[0, 0, 0], [0, 0, c]], [[a, 0, 0], [a, 0, c]], [[a, b, 0], [a, b, c]],
      [[0, 0, c], [a, 0, c]], [[a, 0, c], [a, b, c]], [[a, b, c], [0, b, c]], [[0, b, c], [0, 0, c]]
    ]) edge(at(...from), at(...to), false)

    // The cubes in place. Of a solid block only three sides show: the top of
    // the last layer, the front and the right.
    if (layers > 0) {
      for (let x = 0; x < a; x++) {
        for (let y = b - 1; y >= 0; y--) face([at(x, y, layers), at(x + 1, y, layers), at(x + 1, y + 1, layers), at(x, y + 1, layers)], "#e2e4ff")
      }
      for (let x = 0; x < a; x++) {
        for (let z = 0; z < layers; z++) face([at(x, 0, z), at(x + 1, 0, z), at(x + 1, 0, z + 1), at(x, 0, z + 1)], "#c9cdff")
      }
      for (let y = 0; y < b; y++) {
        for (let z = 0; z < layers; z++) face([at(a, y, z), at(a, y + 1, z), at(a, y + 1, z + 1), at(a, y, z + 1)], "#a5aaff")
      }
    }

    // The frame's near edges again, over the cubes: above a part-filled box
    // the tops of the cubes would otherwise hide them and the box would
    // read as open at the front.
    if (layers < c) {
      edge(at(0, 0, layers), at(0, 0, c), false)
      edge(at(a, 0, layers), at(a, 0, c), false)
      edge(at(0, 0, c), at(a, 0, c), false)
      edge(at(a, 0, c), at(a, b, c), false)
    }

    // The three edges, named: a under the front, b along the right, c up
    // the left.
    const [frontLeft, frontRight, backRight] = [at(0, 0, 0), at(a, 0, 0), at(a, b, 0)]
    this.text(svg, (frontLeft[0] + frontRight[0]) / 2, BASE_Y + 24, `a = ${a}`, "middle")
    this.text(svg, (frontRight[0] + backRight[0]) / 2 + 12, (frontRight[1] + backRight[1]) / 2 + 16, `b = ${b}`, "start")
    this.text(svg, frontLeft[0] - 10, BASE_Y - (c * UNIT) / 2 + 6, `c = ${c}`, "end")
    return svg
  }

  text(svg, x, y, content, anchor) {
    const text = this.node("text", { x, y, "text-anchor": anchor, "font-size": 17, "font-weight": 900, fill: "#312e81" })
    text.textContent = content
    svg.append(text)
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
