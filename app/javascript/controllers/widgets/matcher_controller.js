import { Controller } from "@hotwired/stimulus"
import { setMath } from "../../lib/frac"

// Matcher widget: pair each item on the left with one on the right — an
// expression with its value, a fraction with its percent, a solid with its
// volume formula. {pairs: {leftId: rightId}} is the answer state.
export default class extends Controller {
  static targets = ["list", "hidden"]
  static values = { left: Array, right: Array }

  connect() {
    this.pairs = {}
    this.render()
  }

  render() {
    this.listTarget.replaceChildren(
      ...this.leftValue.map((item) => {
        const id = item.id.toString()
        const row = document.createElement("label")
        row.className = "flex items-center gap-3 rounded-[14px] border-2 border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-2.5"

        const label = document.createElement("span")
        label.className = "flex-1 text-lg font-bold"
        setMath(label, item.label)

        const select = document.createElement("select")
        select.className = "rounded-[10px] border-2 border-[var(--color-border)] bg-white px-2 py-2 text-base font-bold"
        select.append(new Option("—", ""))
        this.rightValue.forEach((option) => {
          const element = new Option(option.label, option.id.toString())
          element.selected = this.pairs[id] === option.id.toString()
          select.append(element)
        })
        select.addEventListener("change", (event) => this.pair(id, event.target.value))

        row.append(label, select)
        return row
      })
    )

    const complete = this.leftValue.every((item) => this.pairs[item.id.toString()])
    this.hiddenTarget.value = complete ? JSON.stringify({ pairs: this.pairs }) : ""
  }

  pair(leftId, rightId) {
    if (rightId) this.pairs[leftId] = rightId
    else delete this.pairs[leftId]
    this.render()
  }
}
