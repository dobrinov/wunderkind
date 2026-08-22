import { Controller } from "@hotwired/stimulus"

// Progressive hint ladder. The rungs live on the server and are fetched one
// per click: the page never contains a hint the student hasn't asked for, and
// the server records the count (hinted correct answers earn less XP), so
// neither can be read or forged from the DOM. Rungs already paid for are
// rendered by the view on load — the rung markup appended here must match
// theirs in assignment_questions/show.html.erb.
export default class extends Controller {
  static targets = ["list", "button"]
  static values = { url: String, total: Number, revealed: Number }

  connect() {
    if (this.revealedValue >= this.totalValue) this.#exhaust()
  }

  async reveal() {
    if (this.revealedValue >= this.totalValue) return
    this.buttonTarget.disabled = true

    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content,
        "Accept": "application/json"
      }
    })
    if (!response.ok) {
      this.buttonTarget.disabled = false
      return
    }

    const data = await response.json()
    if (data.revealed > this.revealedValue) {
      const hint = document.createElement("div")
      hint.className = "rounded-lg bg-reward-100 text-reward-800 px-4 py-2 text-sm"
      hint.textContent = data.rung
      this.listTarget.appendChild(hint)
      this.revealedValue = data.revealed
    }

    if (this.revealedValue >= this.totalValue) this.#exhaust()
    else this.buttonTarget.disabled = false
  }

  #exhaust() {
    this.buttonTarget.disabled = true
    this.buttonTarget.classList.add("opacity-40", "cursor-not-allowed")
  }
}
