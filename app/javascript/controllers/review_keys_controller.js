import { Controller } from "@hotwired/stimulus"

// Review mode's keys: A accepts, E opens the editor, R moves to the box for
// asking the author, X opens the note for returning it, J skips to the next.
// A key typed into a field is text, never a decision — a reviewer writing
// "Можеш ли да добавиш…" must not publish the problem on the first "a" — and
// a key held with a modifier belongs to the browser.
export default class extends Controller {
  static targets = ["accept", "edit", "ask", "decline", "declineNote", "skip"]

  keydown(event) {
    if (event.defaultPrevented || event.metaKey || event.ctrlKey || event.altKey) return
    if (this.isTyping(event.target)) return

    const action = { a: "accept", e: "edit", r: "ask", x: "decline", j: "skip" }[event.key.toLowerCase()]
    if (!action) return

    event.preventDefault()
    this[action]()
  }

  accept() {
    if (this.hasAcceptTarget) this.acceptTarget.click()
  }

  edit() {
    if (this.hasEditTarget) this.editTarget.click()
  }

  ask() {
    if (this.hasAskTarget) this.askTarget.focus()
  }

  decline() {
    if (!this.hasDeclineTarget) return
    this.declineTarget.open = true
    if (this.hasDeclineNoteTarget) this.declineNoteTarget.focus()
  }

  skip() {
    if (this.hasSkipTarget) this.skipTarget.click()
  }

  isTyping(element) {
    if (!element || element === document.body) return false
    return element.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(element.tagName)
  }
}
