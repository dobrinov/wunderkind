import { Controller } from "@hotwired/stimulus"
import { setMath } from "../../lib/frac"

// Ordering widget: the student arranges items into a sequence with
// keyboard-friendly up/down controls; {order: [ids]} is the answer state.
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
        row.className = "flex items-center gap-3 rounded-[14px] border-2 border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-2.5"

        const position = document.createElement("span")
        position.className = "grid size-6 shrink-0 place-items-center rounded-full bg-gray-100 text-xs font-black text-gray-500"
        position.textContent = index + 1

        const label = document.createElement("span")
        label.className = "flex flex-1 justify-center text-2xl font-bold"
        setMath(label, labels[id])

        const controls = document.createElement("span")
        controls.className = "flex shrink-0 gap-1.5"
        controls.append(
          this.moveButton("↑", index === 0, () => this.move(index, -1)),
          this.moveButton("↓", index === this.order.length - 1, () => this.move(index, 1))
        )

        row.append(position, label, controls)
        return row
      })
    )
    this.hiddenTarget.value = JSON.stringify({ order: this.order })
  }

  moveButton(arrow, disabled, onClick) {
    const button = document.createElement("button")
    button.type = "button"
    button.textContent = arrow
    button.disabled = disabled
    button.className = "size-9 rounded-lg border border-[var(--color-border)] font-black disabled:opacity-30"
    button.addEventListener("click", onClick)
    return button
  }

  move(index, delta) {
    const target = index + delta
    ;[this.order[index], this.order[target]] = [this.order[target], this.order[index]]
    this.render()
  }
}
