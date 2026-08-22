import { Controller } from "@hotwired/stimulus"
import { setMath } from "../../lib/frac"

// Multi-select widget: every option is judged on its own, so the student cannot
// stop at the first one that looks right. {selected: [ids]} is the answer state.
// The hidden field stays empty until something is chosen, which keeps the submit
// button from sending an empty answer.
export default class extends Controller {
  static targets = ["list", "hidden"]
  static values = { options: Array }

  connect() {
    this.selected = new Set()
    this.render()
  }

  render() {
    this.listTarget.replaceChildren(
      ...this.optionsValue.map((option) => {
        const id = option.id.toString()
        const chosen = this.selected.has(id)
        const button = document.createElement("button")
        button.type = "button"
        button.setAttribute("aria-pressed", chosen)
        button.className = [
          "choice-button flex items-center gap-3 text-left",
          chosen ? "border-primary-500 bg-primary-50" : ""
        ].join(" ")

        // The tick needs its own size: .choice-button sets a large, heavy face
        // for the option label, and a ✓ at that size spills out of a 20px box.
        const box = document.createElement("span")
        box.className = [
          "grid size-5 shrink-0 place-items-center rounded-[6px] border-2 text-[13px] leading-none",
          chosen ? "border-primary-600 bg-primary-600 text-white" : "border-gray-300"
        ].join(" ")
        box.textContent = chosen ? "✓" : ""

        const label = document.createElement("span")
        setMath(label, option.label)

        button.append(box, label)
        button.addEventListener("click", () => this.toggle(id))
        return button
      })
    )

    this.hiddenTarget.value = this.selected.size
      ? JSON.stringify({ selected: [...this.selected] })
      : ""
  }

  toggle(id) {
    this.selected.has(id) ? this.selected.delete(id) : this.selected.add(id)
    this.render()
  }
}
