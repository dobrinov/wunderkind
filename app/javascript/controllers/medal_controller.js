import { Controller } from "@hotwired/stimulus"

// Opens a badge's detail dialog.
//
// One <dialog> per badge, rendered with the page and found by id, rather than
// one dialog whose contents are swapped: the thing a child taps a medal to see
// is the ladder it belongs to, and that is already server-rendered markup. A
// shared dialog would mean rebuilding it in JavaScript from data attributes,
// which is a second renderer for the same thing.
//
// showModal rather than an `open` attribute, for what it brings: the top
// layer, a focus trap, Esc, and an inert page behind — the same reasons the
// changelog uses it.
export default class extends Controller {
  open({ params: { key } }) {
    this.element.querySelector(`#badge-${CSS.escape(key)}`)?.showModal()
  }

  close(event) {
    event.target.closest("dialog")?.close()
  }
}
