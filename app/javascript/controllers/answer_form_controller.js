import { Controller } from "@hotwired/stimulus"

// Prevents double submission of the answer form, and submits it on Enter.
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

  // Enter is what a child presses after typing an answer, and several of the
  // controls here swallow it: MathLive treats it as its own commit key, and a
  // widget's state lives in a hidden field with no implicit submission of its
  // own. So the form claims Enter itself, in the capture phase, before the
  // control it landed in can act on it.
  //
  // Two deliberate exceptions. A textarea (free text) keeps Enter for a new
  // line and submits on ⌘/Ctrl+Enter. And a form with no submit button is the
  // single-choice grid, where the button *is* the answer: Enter there must
  // reach the focused option so it submits itself, not the form.
  keydown(event) {
    if (event.key !== "Enter" || event.isComposing || event.shiftKey || event.altKey) return

    const inTextarea = event.target.closest("textarea") !== null
    if (inTextarea && !(event.metaKey || event.ctrlKey)) return
    if (!inTextarea && (event.metaKey || event.ctrlKey)) return
    if (event.target.closest("button, a")) return

    const submitter = this.element.querySelector("input[type=submit]")
    if (!submitter) return

    event.preventDefault()
    this.element.requestSubmit(submitter)
  }
}
