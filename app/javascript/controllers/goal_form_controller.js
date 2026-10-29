import { Controller } from "@hotwired/stimulus"

// The goal sentence on a parent's „Нова цел": keeps one chip's menu open at a
// time, closes it once a word is picked, and asks the server for a fresh
// preview of what the child will see. The preview is rendered by the home
// page's own partial (GoalsController#preview), never written here, so the
// two cannot word a goal differently.
//
// None of this is needed to set a goal: the chips are radios in <details> and
// the chip's word follows the checked radio in CSS. This is the polish.
export default class extends Controller {
  static values = { url: String }

  // A tap anywhere else, or focus moving on (tabbing to the next field), closes
  // an open menu. Focus arriving and not blur: a tap on an option's label
  // moves focus nowhere in Safari, and closing on blur would swallow the tap.
  connect() {
    this.closeOutside = (event) => {
      if (!event.target.closest?.(".goal-slot")) this.close()
    }
    document.addEventListener("click", this.closeOutside)
    document.addEventListener("focusin", this.closeOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOutside)
    document.removeEventListener("focusin", this.closeOutside)
    clearTimeout(this.timer)
  }

  // `toggle` does not bubble, so each slot names this action itself.
  toggle(event) {
    if (!event.target.open) return

    this.slots.forEach((slot) => { if (slot !== event.target) slot.open = false })
  }

  choose(event) {
    const slot = event.target.closest(".goal-slot")
    if (!slot) return

    slot.open = false
    slot.querySelector("summary")?.focus()
  }

  close() {
    this.slots.forEach((slot) => { slot.open = false })
  }

  // Debounced: a number typed digit by digit is one preview, not three.
  refresh() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.load(), 250)
  }

  load() {
    const frame = document.getElementById("goal_preview")
    if (!frame) return

    const data = new FormData(this.element)
    data.delete("authenticity_token")
    data.delete("return_to")
    const url = new URL(this.urlValue, window.location.origin)
    url.search = new URLSearchParams(data).toString()
    frame.src = url.toString()
  }

  get slots() {
    return this.element.querySelectorAll(".goal-slot")
  }
}
