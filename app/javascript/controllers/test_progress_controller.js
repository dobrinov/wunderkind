import { Controller } from "@hotwired/stimulus"

// The bar over a grade's test (grade_tests/show): how many of the problems
// have an answer so far. The form works without it; this only shows a child
// how much of the paper is left.
export default class extends Controller {
  static targets = ["meter", "bar", "label", "question"]

  connect() {
    if (!this.hasMeterTarget) return

    this.meterTarget.hidden = false
    this.update = this.update.bind(this)
    this.element.addEventListener("input", this.update)
    this.element.addEventListener("change", this.update)
    this.update()
  }

  disconnect() {
    this.element.removeEventListener("input", this.update)
    this.element.removeEventListener("change", this.update)
  }

  update() {
    const total = this.questionTargets.length
    const done = this.questionTargets.filter((question) => {
      const field = question.querySelector("input[type='text']")
      return field ? field.value.trim() !== "" : question.querySelector("input[type='radio']:checked") !== null
    }).length

    this.barTarget.style.width = `${total === 0 ? 0 : (done / total) * 100}%`
    this.labelTarget.textContent = this.labelTarget.dataset.template.replace("%{done}", done)
  }
}
