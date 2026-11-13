import { Controller } from "@hotwired/stimulus"

// A worked problem on a public page (curriculum/_sample). Its options are drawn
// as the app's answer buttons, so visitors tapped them — and an <li> styled as
// a button did nothing. A tap now answers: the pick turns green or red (and a
// wrong pick shows the right one), and a link to more problems appears under
// it. Nothing is sent anywhere; the answer was already printed on the page.
// The landing page's hero problem is one of these too, with a „pick an answer"
// hint that leaves once one is picked.
export default class extends Controller {
  static targets = ["option", "more", "hint"]

  pick({ currentTarget }) {
    const right = currentTarget.dataset.correct === "true"

    for (const option of this.optionTargets) {
      const picked = option === currentTarget
      const correct = option.dataset.correct === "true"
      option.setAttribute("aria-pressed", picked)
      option.classList.toggle("is-correct", correct && (picked || !right))
      option.classList.toggle("is-wrong", picked && !right)
    }

    if (this.hasMoreTarget) this.moreTarget.hidden = false
    if (this.hasHintTarget) this.hintTarget.hidden = true
  }
}
