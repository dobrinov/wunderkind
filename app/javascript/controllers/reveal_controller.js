import { Controller } from "@hotwired/stimulus"

// Details folded away until asked for: a family's emails, confirmations and
// view-as buttons on the admin people list. The panels are rendered `hidden`,
// so without JavaScript the list is the short one.
export default class extends Controller {
  static targets = ["panel", "button", "label"]
  static values = { open: Boolean, openLabel: String, closedLabel: String }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.panelTargets.forEach((panel) => { panel.hidden = !this.openValue })
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-expanded", this.openValue)
    if (this.hasLabelTarget) this.labelTarget.textContent = this.openValue ? this.openLabelValue : this.closedLabelValue
  }
}
