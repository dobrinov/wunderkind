import { Controller } from "@hotwired/stimulus"
import { play, setSoundEnabled, soundEnabled, unlock } from "../lib/sounds"

// The speaker button on the practice and duel screens. It is not a second,
// looser kind of mute sitting beside the one in Настройки — it is that same
// switch, put where a child actually notices they want it: mid-session, with a
// sleeping sibling in the room. So it takes effect on this page at once and is
// written to the account in the background, and the two screens can never
// disagree about whether sound is on.
export default class extends Controller {
  static targets = ["on", "off"]
  static values = { url: String, onLabel: String, offLabel: String }

  toggle() {
    const enabled = !soundEnabled()
    setSoundEnabled(enabled)
    this.render(enabled)

    // Turning it on says so out loud: this click is a user gesture, which is
    // the one moment a browser will let an AudioContext start, so the
    // confirmation is also what warms the context for the next answer.
    if (enabled) {
      unlock()
      play("correct")
    }

    this.save(enabled)
  }

  render(enabled) {
    this.onTarget.classList.toggle("hidden", !enabled)
    this.offTarget.classList.toggle("hidden", enabled)
    this.element.setAttribute("aria-pressed", String(!enabled))
    this.element.title = enabled ? this.onLabelValue : this.offLabelValue

    // Kept in step so a fresh read of the preference in this document — the
    // sounds module reads it from here on first use — sees the new answer.
    const meta = document.querySelector('meta[name="sound-effects"]')
    if (meta) meta.content = String(enabled)
  }

  // Fire and forget. A choice that fails to save is worth no interruption: it
  // held for this session, and the button is right there to press again.
  save(enabled) {
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content,
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      credentials: "same-origin",
      body: JSON.stringify({ enabled: enabled })
    }).catch(() => {})
  }
}
