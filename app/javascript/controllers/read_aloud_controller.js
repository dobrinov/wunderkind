import { Controller } from "@hotwired/stimulus"
import { speakable, textOf } from "../lib/speakable"
import { track } from "../lib/analytics"

// „Прочети ми" — the problem, and its options as they stand on the screen,
// read out by the device's own Bulgarian voice (speechSynthesis): nothing is
// sent anywhere and nothing is downloaded. In the family field test a
// first-grader could not use the app without her mother, because a problem
// longer than one short sentence was unreadable to her.
//
// The button stays hidden on a device with no Bulgarian voice — a voice for
// another language reading Cyrillic is worse than none. Voices load late on
// iOS, so the check runs again on `voiceschanged`.
export default class extends Controller {
  static targets = ["button", "text"]

  connect() {
    if (!("speechSynthesis" in window)) return
    this.findVoice()
    window.speechSynthesis.addEventListener?.("voiceschanged", this.findVoice)
  }

  disconnect() {
    window.speechSynthesis?.removeEventListener?.("voiceschanged", this.findVoice)
    window.speechSynthesis?.cancel()
  }

  findVoice = () => {
    const voices = window.speechSynthesis.getVoices()
    this.voice = voices.find((voice) => voice.lang?.toLowerCase().startsWith("bg"))
    this.buttonTarget.hidden = !this.voice
  }

  toggle() {
    const synth = window.speechSynthesis
    if (synth.speaking) {
      synth.cancel()
      this.buttonTarget.setAttribute("aria-pressed", "false")
      return
    }

    const utterance = new SpeechSynthesisUtterance(speakable(this.script()))
    utterance.voice = this.voice
    utterance.lang = this.voice.lang
    utterance.rate = 0.9
    utterance.onend = utterance.onerror = () => this.buttonTarget.setAttribute("aria-pressed", "false")
    this.buttonTarget.setAttribute("aria-pressed", "true")
    synth.speak(utterance)
    if (!this.reported) {
      this.reported = true
      track("Read Aloud")
    }
  }

  // The problem's text, then each answer option in the order shown — read off
  // the page, because the options are shuffled per visit.
  script() {
    const parts = [ textOf(this.textTarget).trim() ]
    const options = [ ...document.querySelectorAll(".choice-button") ].map((button) => textOf(button).trim())
    if (options.length) parts.push(`Отговори: ${options.join("; ")}.`)
    return parts.join(" ")
  }
}
