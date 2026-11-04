import { Controller } from "@hotwired/stimulus"

// A file input in the page's own words. The browser's control is drawn in the
// browser's language — „Choose File · No file chosen" on an English Mac in the
// middle of a Bulgarian form — so the input is visually hidden behind a label
// styled as a button, and the chosen file's name is written beside it.
export default class extends Controller {
  static targets = ["input", "name"]
  static values = { empty: String }

  show() {
    const file = this.inputTarget.files[0]
    this.nameTarget.textContent = file ? file.name : this.emptyValue
  }
}
