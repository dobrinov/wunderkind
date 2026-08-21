import { Controller } from "@hotwired/stimulus"

// Drives the live duel screen: counts the shared clock down and polls for the
// opponent's progress.
//
// Polling rather than a websocket, deliberately: the app has no ActionCable
// setup, and a duel needs one small JSON read a second — cheaper than standing
// a cable stack up for one screen. The server owns the clock, the scores and
// the moment the match ends; this reads them and reloads when the phase changes.
export default class extends Controller {
  static values = {
    url: String,
    status: String,
    secondsLeft: Number,
    interval: { type: Number, default: 1500 }
  }

  static targets = [
    "clock",
    "yourScore",
    "yourAnswered",
    "opponentScore",
    "opponentAnswered",
    "waited"
  ]

  connect() {
    this.waited = 0
    this.deadline = Date.now() + this.secondsLeftValue * 1000

    this.ticker = setInterval(() => this.tick(), 1000)
    this.poller = setInterval(() => this.poll(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.ticker)
    clearInterval(this.poller)
  }

  tick() {
    this.waited += 1
    if (this.hasWaitedTarget) this.waitedTarget.textContent = this.waited
    if (!this.hasClockTarget) return

    const left = this.secondsToDeadline()
    this.clockTarget.textContent = `${Math.floor(left / 60)}:${String(left % 60).padStart(2, "0")}`
    // A component class, not a colour utility: .duel-clock owns its own palette,
    // and an unlayered component rule beats a Tailwind utility.
    this.clockTarget.classList.toggle("duel-clock-low", left <= 10)

    // The clock running out does not end the match on its own — the server
    // does, on the next read. Asking for one is what turns 0:00 into a result.
    if (left === 0) this.poll()
  }

  async poll() {
    let state

    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) return
      state = await response.json()
    } catch {
      return // A dropped poll is not worth reporting: the next one is a second away.
    }

    // Lobby filled, or the match ended: the screen is a different screen now.
    if (state.status !== this.statusValue) {
      window.location.reload()
      return
    }

    if (typeof state.seconds_left === "number") {
      this.deadline = Date.now() + state.seconds_left * 1000
    }

    this.update(this.yourScoreTarget, state.you.score)
    this.update(this.yourAnsweredTarget, state.you.answered)
    if (state.opponent) {
      this.update(this.opponentScoreTarget, state.opponent.score)
      this.update(this.opponentAnsweredTarget, state.opponent.answered)
    }
  }

  update(target, value) {
    if (!target || target.textContent === String(value)) return

    target.textContent = value
    target.classList.add("transition-transform", "scale-125")
    setTimeout(() => target.classList.remove("scale-125"), 250)
  }

  secondsToDeadline() {
    return Math.max(0, Math.round((this.deadline - Date.now()) / 1000))
  }
}
