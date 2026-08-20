import { Controller } from "@hotwired/stimulus"
import { MathfieldElement } from "mathlive"

MathfieldElement.fontsDirectory = "/mathlive-fonts"
MathfieldElement.soundsDirectory = null

// A MathLive field for exact-value answers. The student types naturally
// (fractions, decimals, powers); the plain value lands in the hidden input.
export default class extends Controller {
  static targets = ["field", "hidden"]

  connect() {
    this.mathfield = new MathfieldElement()
    this.mathfield.smartFence = true
    this.mathfield.mathVirtualKeyboardPolicy = "auto"
    this.mathfield.style.width = "100%"
    this.fieldTarget.appendChild(this.mathfield)
    this.mathfield.addEventListener("input", () => this.sync())
    this.mathfield.focus()
  }

  disconnect() {
    this.mathfield?.remove()
  }

  sync() {
    // ASCII math is close enough to what the server parses (3/4, 0.75, 75%).
    this.hiddenTarget.value = this.mathfield.getValue("ascii-math")
  }
}
