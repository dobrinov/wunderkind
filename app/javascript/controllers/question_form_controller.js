import { Controller } from "@hotwired/stimulus"

// Drives the admin question editor: the answer type shows its own grading
// section (and the matching part of the student view beside the form),
// options can be added and removed — with a warning when students already
// chose the one being changed — the chosen topics show as chips, and the
// student view follows the text as it is typed. /suggestions uses the same
// controller for its smaller form, which has none of the editor's extras.
export default class extends Controller {
  static targets = [
    "section", "typeSelect", "typeRadio", "widgetSection", "widgetSelect", "optionsList", "optionTemplate",
    "topicCheckbox", "topicChips", "studentBody", "studentOptions", "studentExplanation", "explanation"
  ]

  connect() {
    this.update()
  }

  // The suggestion form picks the type from a select, the admin editor from a
  // row of radios.
  get type() {
    if (this.hasTypeSelectTarget) return this.typeSelectTarget.value
    const checked = this.typeRadioTargets.find((radio) => radio.checked)
    return checked ? checked.value : null
  }

  update() {
    const type = this.type
    this.sectionTargets.forEach((section) => {
      section.classList.toggle("hidden", section.dataset.answerType !== type)
    })
    if (type === "interactive" && this.hasWidgetSelectTarget) this.updateWidget()
    this.mirror()
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
    this.optionsListTarget.lastElementChild?.querySelector("input[type=text]")?.focus()
    this.mirror()
  }

  removeOption(event) {
    event.preventDefault()
    const row = event.target.closest("[data-option-row]")
    const destroyField = row.querySelector("input[name*='_destroy']")
    if (destroyField) {
      destroyField.value = "1"
      // Somebody already chose this option: the row stays as the warning that
      // says so, until the form is saved or left.
      if (Number(row.dataset.chosen) > 0) {
        row.querySelector("[data-option-fields]").classList.add("hidden")
        row.querySelector("[data-option-changed]")?.classList.add("hidden")
        row.querySelector("[data-option-removed]")?.classList.remove("hidden")
      } else {
        row.classList.add("hidden")
      }
      destroyField.dispatchEvent(new Event("input", { bubbles: true }))
    } else {
      row.remove()
      this.element.dispatchEvent(new Event("input", { bubbles: true }))
    }
    this.mirror()
  }

  optionChanged(event) {
    const row = event.target.closest("[data-option-row]")
    const warning = row.querySelector("[data-option-changed]")
    if (!warning) return
    const changed = event.target.value.trim() !== (row.dataset.original || "")
    warning.classList.toggle("hidden", !(changed && Number(row.dataset.chosen) > 0))
  }

  // --- Topics ----------------------------------------------------------------

  syncTopics() {
    const label = this.topicChipsTarget.dataset.removeLabel || "%{name}"
    this.topicChipsTarget.replaceChildren(...this.topicCheckboxTargets.filter((box) => box.checked).map((box) => {
      const chip = document.createElement("span")
      chip.className = "inline-flex h-9 items-center gap-1 rounded-full bg-primary-50 pr-1 pl-3 text-sm font-extrabold text-primary-900"
      chip.append(box.dataset.label)
      const remove = document.createElement("button")
      remove.type = "button"
      remove.className = "grid size-7 cursor-pointer place-items-center rounded-full text-primary-700 hover:bg-primary-100"
      remove.textContent = "×"
      remove.setAttribute("aria-label", label.replace("%{name}", box.dataset.label))
      remove.dataset.action = "question-form#removeTopic"
      remove.dataset.topicId = box.value
      chip.append(remove)
      return chip
    }))
  }

  removeTopic(event) {
    const box = this.topicCheckboxTargets.find((each) => each.value === event.currentTarget.dataset.topicId)
    if (!box) return
    box.checked = false
    box.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // --- The student view ------------------------------------------------------

  // The plain editor draws its own preview under the text box; the student
  // view takes that rendering rather than parsing the text a second time.
  mirror() {
    requestAnimationFrame(() => {
      const preview = this.element.querySelector("[data-plain-editor-target='preview']")
      if (preview && this.hasStudentBodyTarget) this.studentBodyTarget.innerHTML = preview.innerHTML

      if (this.hasStudentOptionsTarget && this.hasOptionsListTarget) {
        const values = Array.from(this.optionsListTarget.querySelectorAll("[data-option-row]"))
          .filter((row) => row.querySelector("input[name*='_destroy']")?.value !== "1")
          .map((row) => row.querySelector("input[type=text]")?.value.trim())
          .filter(Boolean)
        this.studentOptionsTarget.replaceChildren(...values.map((value) => {
          const option = document.createElement("span")
          option.className = "choice-button text-center"
          option.textContent = value
          return option
        }))
      }

      if (this.hasStudentExplanationTarget && this.hasExplanationTarget) {
        this.studentExplanationTarget.textContent = this.explanationTarget.value
      }
    })
  }
}
