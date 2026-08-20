import { Controller } from "@hotwired/stimulus"

// Prevents double submission of the answer form.
//
// Controls are dimmed and made inert rather than `disabled`: on the
// single-choice grid the clicked button *is* the field carrying the answer
// (name="selected_ids[]"), and the browser builds the request payload after the
// submit event, skipping controls that are disabled by then — the answer would
// arrive empty and be graded wrong.
export default class extends Controller {
  submit(event) {
    if (this.submitted) {
      event.preventDefault()
      return
    }
    this.submitted = true

    this.element.querySelectorAll("button, input[type=submit]").forEach((control) => {
      control.classList.add("opacity-50", "cursor-not-allowed", "pointer-events-none")
    })
  }
}
