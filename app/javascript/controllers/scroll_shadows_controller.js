import { Controller } from "@hotwired/stimulus"

// Adds top/bottom shadows to a scrollable container while it can scroll.
export default class extends Controller {
  connect() {
    this.update = this.update.bind(this)
    this.element.addEventListener("scroll", this.update)
    window.addEventListener("resize", this.update)
    this.update()
  }

  disconnect() {
    this.element.removeEventListener("scroll", this.update)
    window.removeEventListener("resize", this.update)
  }

  update() {
    const { scrollTop, scrollHeight, clientHeight } = this.element
    this.element.classList.remove("scroll-shadows-top", "scroll-shadows-bottom")

    if (scrollHeight <= clientHeight) return

    if (scrollTop > 0) this.element.classList.add("scroll-shadows-top")
    if (scrollTop < scrollHeight - clientHeight) this.element.classList.add("scroll-shadows-bottom")
  }
}
