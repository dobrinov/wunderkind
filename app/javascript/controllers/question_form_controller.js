import { Controller } from "@hotwired/stimulus"

// Drives the authoring form: the answer type selects which grading section is
// visible, and multiple-choice options can be added and removed.
export default class extends Controller {
  static targets = ["section", "typeSelect", "widgetSection", "widgetSelect", "optionsList", "optionTemplate"]

  connect() {
    this.update()
  }

  update() {
    const type = this.typeSelectTarget.value
    this.sectionTargets.forEach((section) => {
      section.classList.toggle("hidden", section.dataset.answerType !== type)
    })
    if (type === "interactive") this.updateWidget()
  }

  updateWidget() {
    const widget = this.widgetSelectTarget.value
    this.widgetSectionTargets.forEach((section) => {
      section.classList.toggle("hidden", section.dataset.widget !== widget)
    })
  }

  addOption(event) {
    event.preventDefault()
    const index = Date.now()
    const html = this.optionTemplateTarget.innerHTML.replaceAll("__INDEX__", index)
    this.optionsListTarget.insertAdjacentHTML("beforeend", html)
  }

  removeOption(event) {
    event.preventDefault()
    const row = event.target.closest("[data-option-row]")
    const destroyField = row.querySelector("input[name*='_destroy']")
    if (destroyField) {
      destroyField.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
  }
}
