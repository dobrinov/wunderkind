import { Controller } from "@hotwired/stimulus"

// Progressive hint ladder: reveals one rung per click and records how many
// hints were used into the answer form (hinted correct answers earn less XP).
export default class extends Controller {
  static targets = ["list", "button"]
  static values = { ladder: Array }

  connect() {
    this.revealed = 0
  }

  reveal() {
    if (this.revealed >= this.ladderValue.length) return

    const hint = document.createElement("div")
    hint.className = "rounded-lg bg-reward-100 text-reward-800 px-4 py-2 text-sm"
    hint.textContent = this.ladderValue[this.revealed]
    this.listTarget.appendChild(hint)

    this.revealed += 1
    const field = document.querySelector("input[name='hints_used']")
    if (field) field.value = this.revealed

    if (this.revealed >= this.ladderValue.length) {
      this.buttonTarget.disabled = true
      this.buttonTarget.classList.add("opacity-40", "cursor-not-allowed")
    }
  }
}
