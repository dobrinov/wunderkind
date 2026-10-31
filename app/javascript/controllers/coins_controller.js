import { Controller } from "@hotwired/stimulus"

// Opens a track's dialog in the coin collection („Аз").
//
// One <dialog> per track, rendered with the page and found by id, rather than
// one dialog whose contents are swapped: what a child taps a row to see is its
// ladder of coins, which is already server-rendered markup. showModal for the
// top layer, the focus trap, Esc and an inert page behind.
export default class extends Controller {
  open({ params: { key } }) {
    this.element.querySelector(`#coin-track-${CSS.escape(key)}`)?.showModal()
  }

  close(event) {
    event.target.closest("dialog")?.close()
  }
}
