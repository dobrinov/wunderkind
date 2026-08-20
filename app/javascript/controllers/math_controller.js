import { Controller } from "@hotwired/stimulus"
import katex from "katex"

// Renders an inline LaTeX expression with KaTeX.
export default class extends Controller {
  static values = { latex: String }

  connect() {
    try {
      katex.render(this.latexValue, this.element, { throwOnError: false })
    } catch {
      this.element.textContent = this.latexValue
    }
  }
}
