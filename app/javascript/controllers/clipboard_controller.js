import { Controller } from "@hotwired/stimulus"

// Copies a value to the clipboard and says so. A teacher pasting an invite link
// into a parents' chat has no other way to tell whether the button did anything.
// Where the clipboard API is unavailable (an insecure origin, a browser that
// refuses), the field is selected instead, so ⌘C still works.
export default class extends Controller {
  static targets = ["source", "button"]
  static values = { copied: String }

  async copy() {
    const text = (this.sourceTarget.value ?? this.sourceTarget.textContent).trim()

    try {
      await navigator.clipboard.writeText(text)
    } catch {
      this.sourceTarget.focus()
      this.sourceTarget.select?.()
      return
    }

    if (this.restore) clearTimeout(this.restore)
    this.original ??= this.buttonTarget.textContent
    this.buttonTarget.textContent = this.copiedValue
    this.restore = setTimeout(() => {
      this.buttonTarget.textContent = this.original
    }, 1600)
  }
}
