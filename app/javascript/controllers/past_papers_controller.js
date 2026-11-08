import { Controller } from "@hotwired/stimulus"

// The past papers on a public competition page: one grade's years at a time,
// and the older years past the first few behind „Покажи още". Every grade is
// already in the page; this only shows one.
export default class extends Controller {
  static targets = ["tab", "panel", "more"]

  pick({ params: { grade } }) {
    this.tabTargets.forEach((tab) => {
      const on = Number(tab.dataset.pastPapersGradeParam) === grade
      tab.classList.toggle("is-active", on)
      tab.setAttribute("aria-pressed", on)
    })
    this.panelTargets.forEach((panel) => panel.classList.toggle("hidden", Number(panel.dataset.grade) !== grade))
  }

  more(event) {
    const panel = event.currentTarget.closest("[data-past-papers-target~=panel]")
    panel.querySelectorAll("[data-past-papers-target~=more]").forEach((row) => row.classList.remove("hidden"))
    event.currentTarget.remove()
  }
}
