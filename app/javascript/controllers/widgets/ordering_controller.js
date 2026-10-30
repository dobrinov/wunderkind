import { Controller } from "@hotwired/stimulus"
import { setMath } from "../../lib/frac"

// Ordering widget: the student arranges items into a sequence; {order: [ids]} is
// the answer state.
//
// A row is moved by dragging its grip, which sits on the right where the
// up/down buttons used to. Pointer events (not HTML5 drag and drop, which no
// touch browser implements) make that work with a finger as well as a mouse,
// and it is the grip rather than the whole row that a finger drags, so the list
// does not swallow every scroll that starts on it.
export default class extends Controller {
  static targets = ["list", "hidden"]
  static values = { items: Array }

  connect() {
    // Items arrive pre-shuffled from the server so the DOM never leaks the solution.
    this.order = this.itemsValue.map((item) => item.id.toString())
    this.render()
  }

  render() {
    const labels = Object.fromEntries(this.itemsValue.map((item) => [item.id.toString(), item.label]))
    this.listTarget.replaceChildren(
      ...this.order.map((id, index) => {
        const row = document.createElement("div")
        row.dataset.id = id
        row.className = "flex items-center gap-2 rounded-[14px] border-2 border-[var(--color-border)] bg-[var(--color-surface)] px-2.5 py-2.5 select-none"

        const position = document.createElement("span")
        position.className = "grid size-6 shrink-0 place-items-center rounded-full bg-ink-100 text-xs font-black text-ink-500"
        position.dataset.position = ""
        position.textContent = index + 1

        const label = document.createElement("span")
        label.className = "flex flex-1 justify-center text-2xl font-bold"
        setMath(label, labels[id])

        const grip = document.createElement("span")
        // 48px and ink-500: at 36px in ink-300 the grip was the one control on the
        // screen a child had to find, and on white it was barely there.
        grip.className = "grid size-12 shrink-0 touch-none cursor-grab place-items-center rounded-[10px] text-2xl leading-none text-ink-500 hover:bg-ink-100"
        grip.textContent = "⠿"
        grip.setAttribute("aria-hidden", "true")
        grip.addEventListener("pointerdown", (event) => this.startDrag(event, row))

        row.append(position, label, grip)
        // A mouse can drag from anywhere on the row; a finger cannot, or the
        // list would swallow every scroll that started on it.
        row.addEventListener("pointerdown", (event) => {
          if (event.pointerType === "mouse") this.startDrag(event, row)
        })
        return row
      })
    )
    this.hiddenTarget.value = JSON.stringify({ order: this.order })
  }

  startDrag(event, row) {
    if (this.dragging || event.button > 0) return
    event.preventDefault()

    this.dragging = row
    this.pointerY = event.clientY
    this.offset = 0
    row.style.position = "relative"
    row.classList.add("z-10", "shadow-lg", "cursor-grabbing")

    // On the window, not the row, and without pointer capture: moving the row
    // in the DOM (which is how it changes places) takes it out of the document
    // for an instant, and that silently drops its capture. The rest of the
    // drag then went to whatever was under the finger, the release never
    // reached the row, it stayed lifted, and the order on screen was not the
    // order submitted — a correct answer graded wrong, found twice in the
    // family field test.
    const pointerId = event.pointerId
    const move = (moveEvent) => { if (moveEvent.pointerId === pointerId) this.dragMove(moveEvent) }
    const end = (endEvent) => {
      if (endEvent.pointerId !== pointerId) return
      window.removeEventListener("pointermove", move)
      window.removeEventListener("pointerup", end)
      window.removeEventListener("pointercancel", end)
      this.endDrag(row)
    }
    window.addEventListener("pointermove", move)
    window.addEventListener("pointerup", end)
    window.addEventListener("pointercancel", end)
  }

  dragMove(event) {
    const row = this.dragging
    this.offset += event.clientY - this.pointerY
    this.pointerY = event.clientY

    // The dragged row keeps its layout slot and is only transformed, so its
    // neighbours sit still until it actually changes places with one. Moving it
    // in the DOM moves that slot, so the offset is corrected by however far the
    // row travelled — without that it jumps out from under the finger.
    const before = row.getBoundingClientRect().top
    Array.from(this.listTarget.children).forEach((other) => {
      if (other === row) return

      const box = other.getBoundingClientRect()
      const pointerBelow = event.clientY > box.top + box.height / 2
      const rowIsAbove = Boolean(row.compareDocumentPosition(other) & Node.DOCUMENT_POSITION_FOLLOWING)

      if (pointerBelow && rowIsAbove) this.listTarget.insertBefore(row, other.nextSibling)
      else if (!pointerBelow && !rowIsAbove) this.listTarget.insertBefore(row, other)
    })
    this.offset += before - row.getBoundingClientRect().top

    row.style.transform = `translateY(${this.offset}px)`
    this.renumber()
  }

  endDrag(row) {
    row.style.position = ""
    row.style.transform = ""
    row.classList.remove("z-10", "shadow-lg", "cursor-grabbing")
    this.dragging = null
    // The DOM is the record of where the drag left things; re-render from it so
    // the positions and the answer state agree again.
    this.order = Array.from(this.listTarget.children).map((element) => element.dataset.id)
    this.render()
  }

  // The numbers and the answer both follow the rows as they move, so even a
  // drag that never ends cleanly submits what is on the screen.
  renumber() {
    const rows = Array.from(this.listTarget.children)
    rows.forEach((row, index) => {
      row.querySelector("[data-position]").textContent = index + 1
    })
    this.hiddenTarget.value = JSON.stringify({ order: rows.map((row) => row.dataset.id) })
  }
}
