import { Controller } from "@hotwired/stimulus"

// The switches in Настройки save the moment they are flipped. A form of
// switches with a „Запази" under it is a form where a child flips one, sees it
// flip, and leaves — and nothing was saved. So each change goes to the server
// on its own, and the page says quietly whether it stuck.
//
// The form underneath is a real one, posting every field with its save button,
// and that is what happens without JavaScript; connect() hides the button,
// because with this running it would only offer to save what is already saved.
//
// Nothing here believes a save until the server says what it wrote: the
// response names the values that were actually stored, so a field the account
// may not set, a validation error, or an impersonated session (which refuses
// every write) flips the switch back instead of leaving it showing a choice
// that never happened.
export default class extends Controller {
  static targets = ["fallback", "status"]
  static values = { url: String, saved: String, failed: String }

  connect() {
    this.fallbackTargets.forEach((element) => { element.hidden = true })
    this.queue = Promise.resolve()
  }

  // A checkbox switch: its new state is the value to save, its old one the
  // value to restore.
  toggle(event) {
    const input = event.target
    const restore = () => { input.checked = !input.checked }
    this.save(input.name, input.checked ? "1" : "0", restore)
  }

  // A strip of buttons (the daily minutes), each one a value. Without
  // JavaScript the pressed button submits the form; here it is only that one
  // field, and the strip is redrawn before the answer so the tap feels
  // immediate.
  choose(event) {
    event.preventDefault()
    const button = event.currentTarget
    const group = button.closest("[role='group']")
    const previous = group.querySelector(".is-active")
    const mark = (pressed) => {
      group.querySelectorAll("button").forEach((each) => {
        each.classList.toggle("is-active", each === pressed)
        each.setAttribute("aria-pressed", String(each === pressed))
      })
    }

    mark(button)
    this.save(button.name, button.value, () => mark(previous))
  }

  // One at a time, in the order they were made: two quick flips must reach
  // the server in that order, or the second could land first and the first
  // would win.
  save(name, value, restore) {
    this.queue = this.queue.then(() => this.send(name, value, restore))
  }

  async send(name, value, restore) {
    const body = new FormData()
    body.append(name, value)
    const key = name.match(/\[([^\]]+)\]$/)?.[1]

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content,
          "Accept": "application/json"
        },
        credentials: "same-origin",
        body
      })

      // An admin looking at somebody's account: refused, and the server has
      // put the reason in the flash. Reloading shows it, and shows the
      // switches as they really are.
      if (response.status === 403) {
        window.location.reload()
        return
      }

      const written = response.ok ? await response.json() : {}
      if (!(key in written)) throw new Error("not saved")

      this.report("saved")
    } catch {
      restore()
      this.report("failed")
    }
  }

  report(outcome) {
    if (!this.hasStatusTarget) return

    clearTimeout(this.fade)
    const status = this.statusTarget
    status.textContent = outcome === "saved" ? this.savedValue : this.failedValue
    status.classList.toggle("is-saved", outcome === "saved")
    status.classList.toggle("is-failed", outcome === "failed")

    if (outcome === "saved") {
      this.fade = setTimeout(() => {
        status.textContent = ""
        status.classList.remove("is-saved")
      }, 2500)
    }
  }

  disconnect() {
    clearTimeout(this.fade)
  }
}
