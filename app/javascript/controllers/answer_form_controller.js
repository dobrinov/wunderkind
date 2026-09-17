import { Controller } from "@hotwired/stimulus"
import { play, soundEnabled, unlock } from "../lib/sounds"

// Prevents double submission of the answer form, submits it on Enter, and —
// when the student has sounds on — plays the right/wrong cue before moving on.
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

    // Inside the click, which is the only place an AudioContext is allowed to
    // start. Chrome would also let the *next* page start one, since it inherits
    // this document's activation, but WebKit and Firefox would not — so the cue
    // is played back here, on this page, and the answer is posted rather than
    // navigated to. See lib/sounds.js.
    unlock()
    const body = this.payload(event.submitter)

    this.submitted = true
    this.element.querySelectorAll("button, input[type=submit]").forEach((control) => {
      control.classList.add("opacity-50", "cursor-not-allowed", "pointer-events-none")
    })

    if (body === null) return // Nothing to play, or no way to post it: submit as a plain form.

    event.preventDefault()
    this.post(body)
  }

  // The form as the browser would have posted it, or null to let the browser
  // post it after all. Two things can send us down that road: sounds being off,
  // which is most of the reason this path exists, and a browser too old for
  // FormData's submitter argument — there the clicked option's value would be
  // missing from the body and a correct answer would be graded wrong, so the
  // check below is on the value itself rather than on a version number.
  payload(submitter) {
    if (!soundEnabled()) return null

    let body
    try {
      body = new FormData(this.element, submitter)
    } catch {
      return null
    }

    if (submitter && submitter.name && !body.getAll(submitter.name).includes(submitter.value)) return null

    return body
  }

  async post(body) {
    let outcome

    try {
      const response = await fetch(this.element.action, {
        method: "POST",
        body: body,
        headers: { Accept: "application/json" },
        credentials: "same-origin"
      })
      if (!response.ok) throw new Error(response.status)
      outcome = await response.json()
    } catch {
      // The answer may well have been recorded before this went wrong, and one
      // answer per question is a database constraint — so never re-post it.
      // Reloading asks the server what actually happened: the feedback card if
      // the answer landed, the untouched question if it did not.
      window.location.reload()
      return
    }

    // Navigating tears the audio down with the document, so the cue is given
    // the length of its own two notes before the next page is asked for.
    const ringing = play(outcome.verdict)
    const advance = () => { window.location.href = outcome.redirect }

    if (ringing > 0) {
      setTimeout(advance, ringing)
    } else {
      advance()
    }
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
