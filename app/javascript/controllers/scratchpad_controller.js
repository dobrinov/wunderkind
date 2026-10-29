import { Controller } from "@hotwired/stimulus"

// „Чернова": squared paper beside the problem, to work a sum out on with a
// finger or a mouse. It is the child's and nobody else's — never sent to the
// server, never graded, not seen by a parent. What is drawn is kept for the
// browser session under the question's key, so it survives the reload that
// shows the feedback card (the child can compare their working with „Защо")
// and is gone on the next problem, which has a key of its own.
//
// Strokes are kept as points and redrawn, rather than painted once onto the
// canvas, so the paper can be resized (a tablet turned sideways) and undo is
// just dropping the last stroke. The eraser is a stroke too, drawn with
// `destination-out`, so undo brings back what it rubbed out.
export default class extends Controller {
  static targets = ["panel", "canvas", "toggle", "pen", "eraser", "empty"]
  static values = { key: String }

  connect() {
    this.strokes = this.load()
    this.tool = "pen"
    this.resizeObserver = new ResizeObserver(() => this.resize())
    this.resizeObserver.observe(this.canvasTarget)
    this.syncTools()
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    document.body.classList.remove("scratchpad-open")
  }

  toggle() {
    const open = this.panelTarget.hidden
    this.panelTarget.hidden = !open
    this.toggleTarget.setAttribute("aria-expanded", String(open))
    document.body.classList.toggle("scratchpad-open", open)
    if (open) this.resize()
  }

  pen() { this.tool = "pen"; this.syncTools() }
  eraser() { this.tool = "eraser"; this.syncTools() }

  undo() {
    this.strokes.pop()
    this.save()
    this.redraw()
  }

  clear() {
    this.strokes = []
    this.save()
    this.redraw()
  }

  down(event) {
    event.preventDefault()
    // Best effort: capture keeps a stroke that leaves the paper attached to
    // it, but a pointer the browser no longer tracks (or a synthetic one)
    // throws, and that must not cost the stroke.
    try { this.canvasTarget.setPointerCapture(event.pointerId) } catch { /* drawn without capture */ }
    this.current = { tool: this.tool, points: [ this.point(event) ] }
    this.strokes.push(this.current)
    this.redraw()
  }

  move(event) {
    if (!this.current) return
    // Coalesced events: a fast finger on an iPad reports several positions per
    // frame, and drawing only the last one turns a curve into a polygon.
    // WebKit can hand back an empty list, which would drop the move entirely.
    const coalesced = event.getCoalescedEvents ? event.getCoalescedEvents() : []
    const events = coalesced.length ? coalesced : [ event ]
    events.forEach((each) => this.current.points.push(this.point(each)))
    this.redraw()
  }

  up() {
    if (!this.current) return
    this.current = null
    this.save()
  }

  // Points are stored as fractions of the paper, so a resized canvas keeps
  // the drawing where it was relative to the grid.
  point(event) {
    const rect = this.canvasTarget.getBoundingClientRect()
    return [ (event.clientX - rect.left) / rect.width, (event.clientY - rect.top) / rect.height ]
  }

  resize() {
    const canvas = this.canvasTarget
    const ratio = window.devicePixelRatio || 1
    const { width, height } = canvas.getBoundingClientRect()
    if (width === 0 || height === 0) return
    canvas.width = Math.round(width * ratio)
    canvas.height = Math.round(height * ratio)
    this.redraw()
  }

  redraw() {
    const canvas = this.canvasTarget
    const context = canvas.getContext("2d")
    const ratio = window.devicePixelRatio || 1
    context.clearRect(0, 0, canvas.width, canvas.height)
    context.lineCap = "round"
    context.lineJoin = "round"

    this.strokes.forEach((stroke) => {
      context.globalCompositeOperation = stroke.tool === "eraser" ? "destination-out" : "source-over"
      context.strokeStyle = "#27273d"
      context.lineWidth = (stroke.tool === "eraser" ? 22 : 3) * ratio
      context.beginPath()
      stroke.points.forEach(([ x, y ], index) => {
        const px = x * canvas.width
        const py = y * canvas.height
        if (index === 0) context.moveTo(px, py)
        else context.lineTo(px, py)
      })
      if (stroke.points.length === 1) context.lineTo(stroke.points[0][0] * canvas.width + 0.1, stroke.points[0][1] * canvas.height)
      context.stroke()
    })
    context.globalCompositeOperation = "source-over"
    this.emptyTarget.hidden = this.strokes.some((stroke) => stroke.tool === "pen")
  }

  syncTools() {
    this.penTarget.setAttribute("aria-pressed", String(this.tool === "pen"))
    this.eraserTarget.setAttribute("aria-pressed", String(this.tool === "eraser"))
  }

  load() {
    try {
      return JSON.parse(sessionStorage.getItem(this.keyValue)) || []
    } catch {
      return []
    }
  }

  save() {
    try {
      sessionStorage.setItem(this.keyValue, JSON.stringify(this.strokes))
    } catch {
      // A private window or a full quota: the paper still works, it just
      // will not survive the reload to the feedback card.
    }
  }
}
