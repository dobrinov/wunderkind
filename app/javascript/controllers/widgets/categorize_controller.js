import { Controller } from "@hotwired/stimulus"
import { setMath } from "../../lib/frac"

// Categorize widget: every item goes into one of a few named groups — prime or
// composite, rational or irrational, tessellates or does not.
// {assignment: {itemId: binId}} is the answer state, submitted once every item
// has been placed. Buttons rather than drag and drop, so it works on a phone
// and from a keyboard.
export default class extends Controller {
  static targets = ["list", "hidden"]
  static values = { items: Array, bins: Array }

  connect() {
    this.assignment = {}
    this.render()
  }

  render() {
    this.listTarget.replaceChildren(
      ...this.itemsValue.map((item) => {
        const id = item.id.toString()
        const row = document.createElement("div")
        row.className = "flex flex-wrap items-center justify-between gap-2 rounded-[14px] border-2 border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-2.5"

        const label = document.createElement("span")
        label.className = "text-xl font-bold"
        setMath(label, item.label)

        const choices = document.createElement("div")
        choices.className = "flex flex-wrap gap-1.5"
        this.binsValue.forEach((bin) => {
          const binId = bin.id.toString()
          const chosen = this.assignment[id] === binId
          const button = document.createElement("button")
          button.type = "button"
          button.textContent = bin.label
          button.setAttribute("aria-pressed", chosen)
          button.className = [
            "rounded-full border-2 px-3 py-1.5 text-sm font-black transition-colors",
            chosen ? "border-primary-600 bg-primary-600 text-white" : "border-[var(--color-border)] text-gray-600"
          ].join(" ")
          button.addEventListener("click", () => this.assign(id, binId))
          choices.append(button)
        })

        row.append(label, choices)
        return row
      })
    )

    const complete = this.itemsValue.every((item) => this.assignment[item.id.toString()])
    this.hiddenTarget.value = complete ? JSON.stringify({ assignment: this.assignment }) : ""
  }

  assign(itemId, binId) {
    this.assignment[itemId] = binId
    this.render()
  }
}
