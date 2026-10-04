import { Controller } from "@hotwired/stimulus"

// Reloads the turbo-frame it is attached to, on an interval.
//
// For lists that go stale while somebody is looking at them — the duel lobby
// browser, where a room that opened ten seconds ago is the whole point. The
// frame reloads itself rather than the page, so a student reading the list
// does not have it yanked out from under them, and the interval stops with the
// element so a backgrounded tab is not polling forever.
export default class extends Controller {
  static values = { interval: { type: Number, default: 5000 } }

  connect() {
    this.timer = setInterval(() => this.refresh(), this.intervalValue)
    // A tab that is not being looked at has nothing to keep up to date.
    this.visibility = () => { if (!document.hidden) this.refresh() }
    document.addEventListener("visibilitychange", this.visibility)
  }

  disconnect() {
    clearInterval(this.timer)
    document.removeEventListener("visibilitychange", this.visibility)
  }

  refresh() {
    if (document.hidden) return

    this.element.reload()
  }
}
