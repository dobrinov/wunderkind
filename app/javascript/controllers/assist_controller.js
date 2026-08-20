import { Controller } from "@hotwired/stimulus"

// Authoring assistant panel: sends the current question draft to the server,
// shows the model's suggestions for the author to copy from.
export default class extends Controller {
  static targets = ["output", "panel"]
  static values = { url: String }

  async request(event) {
    const kind = event.currentTarget.dataset.kind
    this.panelTarget.classList.remove("hidden")
    this.outputTarget.textContent = "…"

    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
      },
      body: JSON.stringify({
        kind,
        body_text: this.draftText(),
        answer: this.draftAnswer()
      })
    })

    const payload = await response.json().catch(() => ({}))
    this.outputTarget.textContent = payload.suggestions || payload.error || "—"
  }

  draftText() {
    const field = document.querySelector("input[name='question[body_json]']")
    if (!field?.value) return ""
    try {
      return this.textOf(JSON.parse(field.value))
    } catch {
      return ""
    }
  }

  textOf(node) {
    if (node.type === "text") return node.text || ""
    if (node.type === "math") return node.attrs?.latex || ""
    return (node.content || []).map((child) => this.textOf(child)).join(node.type === "doc" ? "\n" : "")
  }

  draftAnswer() {
    return document.querySelector("input[name='question[expected]']")?.value || ""
  }
}
