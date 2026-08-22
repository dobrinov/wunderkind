import { Controller } from "@hotwired/stimulus"

// Blanks widget: one or more numbered boxes to fill in — the missing digits of
// a written sum, both roots of an equation, the three angles of a triangle.
// {values: {fieldId: text}} is the answer state, and it is only submitted once
// every box has something in it.
export default class extends Controller {
  static targets = ["list", "hidden"]
  static values = { fields: Array }

  connect() {
    this.values = {}
    this.render()
  }

  render() {
    // One grid for the whole list, and every row a subgrid of it, so the label
    // column is as wide as the longest label and the boxes line up under each
    // other — a label sized per row puts the boxes of "втора колонка" and
    // "четвърта колонка" in two different places. The label column's floor is
    // min-content and the box's is 3rem, so on a narrow card the box gives way
    // first and a one-word label breaks only if the card is narrower than the
    // word.
    const has = (key) => this.fieldsValue.some((field) => (field[key] ?? "").toString() !== "")
    const columns = [ has("label") && "minmax(min-content, max-content)", "minmax(3rem, 8rem)", has("unit") && "max-content" ]
    this.listTarget.style.display = "grid"
    this.listTarget.style.gridTemplateColumns = columns.filter(Boolean).join(" ")
    this.listTarget.style.justifyContent = "center"
    this.listTarget.style.columnGap = "0.75rem"

    this.listTarget.replaceChildren(
      ...this.fieldsValue.map((field, index) => {
        const id = field.id.toString()
        const row = document.createElement("label")
        row.className = "grid items-center gap-3"
        row.style.gridTemplateColumns = "subgrid"
        row.style.gridColumn = "1 / -1"

        if (has("label")) {
          const label = document.createElement("span")
          label.className = "text-right text-lg font-bold break-words text-gray-700"
          label.textContent = field.label ?? ""
          row.append(label)
        }

        const input = document.createElement("input")
        input.type = "text"
        input.inputMode = "decimal"
        input.autocomplete = "off"
        input.autofocus = index === 0
        input.className = "w-full min-w-0 rounded-[14px] border-2 border-gray-300 px-3 py-2.5 text-center text-2xl font-black outline-0 focus:border-primary-600"
        input.value = this.values[id] ?? ""
        input.addEventListener("input", (event) => this.update(id, event.target.value))
        row.append(input)

        if (has("unit")) {
          const unit = document.createElement("span")
          unit.className = "text-lg font-bold text-gray-500"
          unit.textContent = field.unit ?? ""
          row.append(unit)
        }

        return row
      })
    )
    this.sync()
  }

  update(id, value) {
    this.values[id] = value
    this.sync()
  }

  sync() {
    const complete = this.fieldsValue.every((field) => (this.values[field.id.toString()] ?? "").trim() !== "")
    this.hiddenTarget.value = complete ? JSON.stringify({ values: this.values }) : ""
  }
}
