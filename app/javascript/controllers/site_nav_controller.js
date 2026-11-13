import { Controller } from "@hotwired/stimulus"

// The public menu (layouts/landingpage). The dropdowns are <details> and the
// links are all in the HTML, so this only adds manners: the menu button opens
// the drawer on a phone, one dropdown is open at a time, and a click
// elsewhere, Escape or leaving the page closes what is open.
export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.closeAll = this.closeAll.bind(this)
    // A snapshot cached with the drawer open would flash it on the way back.
    document.addEventListener("turbo:before-cache", this.closeAll)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.closeAll)
  }

  toggle() {
    const open = this.element.classList.toggle("is-open")
    this.buttonTarget.setAttribute("aria-expanded", open)
  }

  // A dropdown opened: close the others.
  opened({ currentTarget }) {
    if (!currentTarget.open) return
    for (const menu of this.menuTargets) if (menu !== currentTarget) menu.open = false
  }

  outside({ target }) {
    if (!this.element.contains(target)) this.closeAll()
  }

  closeAll() {
    for (const menu of this.menuTargets) menu.open = false
    this.element.classList.remove("is-open")
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-expanded", "false")
  }
}
