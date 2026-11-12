import { Controller } from "@hotwired/stimulus"

// The grade picker on the hub (curriculum/index). Each grade is a link to its
// page and every grade's panel is in the HTML; with this running, a tap on a
// grade shows its panel instead of leaving, so a parent sees what a grade has
// — problems, test, formulas, exam, topics — before choosing where to go.
export default class extends Controller {
  static targets = ["tab", "panel"]

  pick(event) {
    event.preventDefault()
    const grade = event.currentTarget.dataset.grade

    for (const tab of this.tabTargets) {
      const on = tab.dataset.grade === grade
      tab.setAttribute("aria-pressed", on)
      tab.classList.toggle("is-on", on)
    }
    for (const panel of this.panelTargets) panel.hidden = panel.dataset.grade !== grade
  }
}
