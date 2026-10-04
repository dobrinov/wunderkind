import { Controller } from "@hotwired/stimulus"

// Opens the „Какво е новото" dialog and makes every way out of it the same way
// out: the form that records on the server that the person has been told.
//
// showModal() rather than the `open` attribute, because only showModal puts
// the element in the top layer, traps focus inside it and makes the page
// behind it inert — which is the whole reason this is a <dialog> and not a
// styled div. Esc fires `cancel` and a click on the backdrop lands on the
// dialog element itself (its children are inside the padding box, so a click
// on the box but not on a child *is* the backdrop); both press the button.
export default class extends Controller {
  static targets = ["form"]

  connect() {
    if (!this.element.open) this.element.showModal()
  }

  acknowledge(event) {
    // Stops Esc from closing the dialog on its own: the close has to be the
    // round trip, or the next page would open it again having learned nothing.
    event.preventDefault()
    if (this.submitted) return

    this.submitted = true
    this.formTarget.requestSubmit()
  }

  backdrop(event) {
    if (event.target === this.element) this.acknowledge(event)
  }
}
