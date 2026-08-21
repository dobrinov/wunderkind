import { Controller } from "@hotwired/stimulus"

// Show/hide for a section that is folded away on a phone and open on a desktop.
// The panel carries its own responsive classes (`hidden sm:grid`); this only
// flips the phone half of that, so widening the window never leaves a section
// stuck shut.
export default class extends Controller {
  static targets = ["panel", "chevron"]
  static values = { open: Boolean }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.panelTargets.forEach((panel) => panel.classList.toggle("max-sm:hidden", !this.openValue))
    this.chevronTargets.forEach((chevron) => { chevron.textContent = this.openValue ? "−" : "+" })
  }
}
