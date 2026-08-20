import { Controller } from "@hotwired/stimulus"

// Prevents double submission of the answer form.
export default class extends Controller {
  static targets = ["submit"]

  submit() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.classList.add("opacity-50", "cursor-not-allowed")
    }
    this.element.querySelectorAll("button").forEach((button) => {
      button.disabled = true
      button.classList.add("opacity-50", "cursor-not-allowed")
    })
  }
}
