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
        position.className = "grid size-6 shrink-0 place-items-center rounded-full bg-gray-100 text-xs font-black text-gray-500"
        position.dataset.position = ""
        position.textContent = index + 1

        const label = document.createElement("span")
        label.className = "flex flex-1 justify-center text-2xl font-bold"
        setMath(label, labels[id])

        // Sized like the buttons it replaced, so a finger has the same target.
        const grip = document.createElement("span")
        grip.className = "grid size-9 shrink-0 touch-none cursor-grab place-items-center text-xl leading-none text-gray-300"
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
    row.setPointerCapture(event.pointerId)

    const move = (moveEvent) => this.dragMove(moveEvent)
    const end = (endEvent) => {
      row.removeEventListener("pointermove", move)
      row.removeEventListener("pointerup", end)
      row.removeEventListener("pointercancel", end)
      row.releasePointerCapture(endEvent.pointerId)
      this.endDrag(row)
    }
    row.addEventListener("pointermove", move)
    row.addEventListener("pointerup", end)
    row.addEventListener("pointercancel", end)
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

  renumber() {
    Array.from(this.listTarget.children).forEach((row, index) => {
      row.querySelector("[data-position]").textContent = index + 1
    })
  }
}
