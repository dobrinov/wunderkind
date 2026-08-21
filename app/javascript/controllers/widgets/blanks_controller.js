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
    // Every row shares one column template, sized to the longest label and the
    // longest unit, so the boxes line up under each other — with a label per
    // row sized to its own text, "втора колонка" and "четвърта колонка" put
    // their inputs in two different places.
    const widest = (key) => Math.max(0, ...this.fieldsValue.map((field) => (field[key] ?? "").toString().length))
    const track = (chars) => (chars ? `minmax(0, ${chars + 1}ch)` : "")
    const template = [ track(widest("label")), "8rem", track(widest("unit")) ].filter(Boolean).join(" ")

    this.listTarget.replaceChildren(
      ...this.fieldsValue.map((field, index) => {
        const id = field.id.toString()
        const row = document.createElement("label")
        row.className = "grid items-center justify-center gap-3"
        row.style.gridTemplateColumns = template

        if (widest("label")) {
          const label = document.createElement("span")
          label.className = "text-right text-lg font-bold text-gray-700"
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

        if (widest("unit")) {
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
