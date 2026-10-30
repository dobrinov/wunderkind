import { Controller } from "@hotwired/stimulus"
import { track } from "../lib/analytics"

// „Чернова": squared paper beside the problem, to work a sum out on with a
// finger or a mouse, or to type numbers onto. It is the child's and nobody
// else's — never sent to the server, never graded, not seen by a parent. What
// is on it is kept for the browser session under the question's key, so it
// survives the reload that shows the feedback card (the child can compare
// their working with „Защо") and is gone on the next problem, which has a key
// of its own.
//
// Marks are kept as data and redrawn, rather than painted once onto the
// canvas, so the paper can be resized (a tablet turned sideways) and undo is
// just dropping the last mark. A mark is a stroke (pen or eraser — the eraser
// is drawn with `destination-out`, so undo brings back what it rubbed out) or
// a typed note at the spot that was tapped.
//
// Nobody found the paper while it was only a button in the header, so it has
// more than one door (`toggle` targets: the header, and one under the answer
// controls) and opens by itself beside a word problem or a figure on a
// landscape screen (`suggested`). A child who closes it there has said they do
// not want it, which is remembered for the device until they open it again.
const PREFERENCE = "scratchpad-auto"
const WIDE = "(min-width: 1024px) and (min-aspect-ratio: 1/1)"
const INK = "#27273d"
const NOTE_SIZE = 20

export default class extends Controller {
  static targets = ["panel", "canvas", "toggle", "pen", "text", "eraser", "empty", "note"]
  static values = { key: String, suggested: Boolean }

  connect() {
    // A duel screen between problems has no paper on it.
    if (!this.hasPanelTarget) return

    this.marks = this.load()
    this.tool = "pen"
    this.resizeObserver = new ResizeObserver(() => this.resize())
    this.resizeObserver.observe(this.canvasTarget)
    this.syncTools()

    // Open again on the feedback card if it was open when the answer went in;
    // open by itself on a problem worth working out, where there is room.
    if (this.read(this.openKey) === "1") {
      this.open({ by: "restore" })
    } else if (this.suggestedValue && window.matchMedia(WIDE).matches && this.readLocal(PREFERENCE) !== "off") {
      this.open({ by: "auto" })
    }
  }

  // Kept apart from the marks' own key, which a spec (and anything else)
  // finds by its "scratchpad-" prefix.
  get openKey() {
    return `open:${this.keyValue}`
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    document.body.classList.remove("scratchpad-open")
  }

  toggle() {
    if (this.panelTarget.hidden) {
      this.open({ by: "child" })
    } else {
      this.close()
    }
  }

  open({ by }) {
    this.openedBy = by
    this.setOpen(true)
    // The child's own choice: auto-opening may come back.
    if (by === "child") this.writeLocal(PREFERENCE, "on")
    // Once per problem, and only when the child reached for it: whether they
    // go looking for it is the question, and auto-opening would answer it.
    if (by === "child" && !this.reported) {
      this.reported = true
      track("Scratchpad Opened")
    }
  }

  close() {
    this.commitNote()
    this.setOpen(false)
    if (this.openedBy === "auto") this.writeLocal(PREFERENCE, "off")
  }

  setOpen(open) {
    this.panelTarget.hidden = !open
    this.toggleTargets.forEach((toggle) => toggle.setAttribute("aria-expanded", String(open)))
    document.body.classList.toggle("scratchpad-open", open)
    this.write(this.openKey, open ? "1" : "0")
    if (open) this.resize()
  }

  pen() { this.useTool("pen") }
  text() { this.useTool("text") }
  eraser() { this.useTool("eraser") }

  useTool(tool) {
    this.commitNote()
    this.tool = tool
    this.syncTools()
  }

  undo() {
    this.commitNote()
    this.marks.pop()
    this.save()
    this.redraw()
  }

  clear() {
    this.cancelNote()
    this.marks = []
    this.save()
    this.redraw()
  }

  // --- Drawing ----------------------------------------------------------------

  down(event) {
    // A note is placed on the click, not here: refusing a touch pointerdown
    // would cancel the tap in Safari, and the keyboard only comes up for a
    // field focused inside a click.
    if (this.tool === "text") return

    event.preventDefault()
    this.commitNote()
    // Best effort: capture keeps a stroke that leaves the paper attached to
    // it, but a pointer the browser no longer tracks (or a synthetic one)
    // throws, and that must not cost the stroke.
    try { this.canvasTarget.setPointerCapture(event.pointerId) } catch { /* drawn without capture */ }
    this.current = { tool: this.tool, points: [ this.point(event) ] }
    this.marks.push(this.current)
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
    if (this.current.tool === "pen") this.used("pen")
    this.current = null
    this.save()
  }

  // --- Typing -----------------------------------------------------------------

  place(event) {
    if (this.tool !== "text") return
    this.commitNote()

    const note = this.noteTarget
    const [ x, y ] = this.point(event)
    this.noteAt = [ x, y ]
    note.value = ""
    note.hidden = false
    note.style.top = `${y * 100}%`
    // Near the right edge the field would run off the paper; it starts far
    // enough left to fit, and the note is drawn where the field starts.
    const paper = this.canvasTarget.getBoundingClientRect()
    const room = Math.max(0, 1 - note.offsetWidth / paper.width)
    this.noteAt = [ Math.min(x, room), y ]
    note.style.left = `${this.noteAt[0] * 100}%`
    note.focus({ preventScroll: true })
  }

  noteKey(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.commitNote()
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.cancelNote()
    }
  }

  commitNote() {
    if (!this.hasNoteTarget || this.noteTarget.hidden) return
    const text = this.noteTarget.value.trim()
    if (text) {
      this.marks.push({ tool: "text", at: this.noteAt, text })
      this.used("text")
      this.save()
    }
    this.cancelNote()
    this.redraw()
  }

  cancelNote() {
    if (!this.hasNoteTarget) return
    this.noteTarget.hidden = true
    this.noteTarget.value = ""
  }

  // The first thing written on the paper for this problem — the number that
  // says whether opening it by itself was worth the room it takes.
  used(tool) {
    if (this.usedReported) return
    this.usedReported = true
    track("Scratchpad Used", { tool, opened: this.openedBy || "child" })
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

    this.marks.forEach((mark) => {
      if (mark.tool === "text") {
        context.globalCompositeOperation = "source-over"
        context.fillStyle = INK
        context.font = `600 ${NOTE_SIZE * ratio}px ui-rounded, "Nunito", system-ui, sans-serif`
        context.textBaseline = "middle"
        context.fillText(mark.text, mark.at[0] * canvas.width, mark.at[1] * canvas.height)
        return
      }

      context.globalCompositeOperation = mark.tool === "eraser" ? "destination-out" : "source-over"
      context.strokeStyle = INK
      context.lineWidth = (mark.tool === "eraser" ? 22 : 3) * ratio
      context.beginPath()
      mark.points.forEach(([ x, y ], index) => {
        const px = x * canvas.width
        const py = y * canvas.height
        if (index === 0) context.moveTo(px, py)
        else context.lineTo(px, py)
      })
      if (mark.points.length === 1) context.lineTo(mark.points[0][0] * canvas.width + 0.1, mark.points[0][1] * canvas.height)
      context.stroke()
    })
    context.globalCompositeOperation = "source-over"
    this.emptyTarget.hidden = this.marks.some((mark) => mark.tool !== "eraser")
  }

  syncTools() {
    this.penTarget.setAttribute("aria-pressed", String(this.tool === "pen"))
    this.textTarget.setAttribute("aria-pressed", String(this.tool === "text"))
    this.eraserTarget.setAttribute("aria-pressed", String(this.tool === "eraser"))
    this.canvasTarget.classList.toggle("is-text", this.tool === "text")
  }

  // --- Storage ----------------------------------------------------------------

  // The marks (and whether the paper was open) last the browser session; the
  // child's „do not open it by itself" lasts the device. A private window or a
  // full quota costs only that: the paper still works.
  load() {
    try {
      return JSON.parse(sessionStorage.getItem(this.keyValue)) || []
    } catch {
      return []
    }
  }

  save() {
    try {
      sessionStorage.setItem(this.keyValue, JSON.stringify(this.marks))
    } catch {
      // Not kept for the feedback card, that is all.
    }
  }

  read(key) {
    try { return sessionStorage.getItem(key) } catch { return null }
  }

  write(key, value) {
    try { sessionStorage.setItem(key, value) } catch { /* not kept */ }
  }

  readLocal(key) {
    try { return localStorage.getItem(key) } catch { return null }
  }

  writeLocal(key, value) {
    try { localStorage.setItem(key, value) } catch { /* not kept */ }
  }
}
