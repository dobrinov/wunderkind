import { Controller } from "@hotwired/stimulus"
import { trackThen } from "../lib/analytics"

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
    // -1 rather than 0 for "not counting down": zero is a second of the
    // countdown and has to stay distinguishable from its absence.
    startsIn: { type: Number, default: -1 },
    interval: { type: Number, default: 1500 }
  }

  static targets = [
    "clock",
    "yourScore",
    "yourAnswered",
    "opponentScore",
    "opponentAnswered",
    "waited",
    "yourReady",
    "opponentReady",
    "readyPanel",
    "countdown",
    "countdownNumber"
  ]

  connect() {
    this.waited = 0
    this.deadline = Date.now() + this.secondsLeftValue * 1000
    this.startsAt = this.startsInValue >= 0 ? Date.now() + this.startsInValue * 1000 : null

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

    this.tickCountdown()
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

  // The five seconds between both players readying and the first problem. The
  // number comes off the server's own timestamp — both screens count the same
  // seconds down — and reaching zero asks for a poll rather than navigating,
  // because the server is what turns a finished countdown into a live match.
  tickCountdown() {
    if (!this.hasCountdownNumberTarget || this.startsAt === null) return

    const left = Math.max(0, Math.ceil((this.startsAt - Date.now()) / 1000))

    // Setting textContent does not restart a CSS animation, so each digit has
    // to be given a fresh element to be born into — otherwise only the first
    // number of the five pops and the rest change in silence.
    if (this.countdownNumberTarget.textContent !== String(left)) {
      this.countdownNumberTarget.replaceChildren(document.createTextNode(String(left)))
      this.countdownNumberTarget.classList.remove("is-counting")
      void this.countdownNumberTarget.offsetWidth
      this.countdownNumberTarget.classList.add("is-counting")
    }

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

    // The poll paired this player into somebody else's room while they waited
    // in their own: the page they are on is not their match any more.
    if (state.redirect) {
      window.location.href = state.redirect
      return
    }

    // Lobby filled, countdown run out, or the match ended: the screen is a
    // different screen now.
    if (state.status !== this.statusValue) {
      // The result is counted here rather than on the result screen, and here
      // rather than on the server, because this is the only moment that happens
      // exactly once per player per match: the result screen can be reopened
      // from the history all week, and a match that ends on the clock ends
      // without either player making a request that would notice. The reload
      // waits on the event, which would otherwise cancel it — see trackThen.
      if (state.result) {
        trackThen("Duel Finished", { result: state.result }, () => window.location.reload())
      } else {
        window.location.reload()
      }

      return
    }

    if (typeof state.seconds_left === "number") {
      this.deadline = Date.now() + state.seconds_left * 1000
    }

    if (this.hasReadyPanelTarget) {
      this.markReady(this.yourReadyTarget, state.you.ready)
      this.markReady(this.opponentReadyTarget, state.opponent && state.opponent.ready)

      // The countdown replaces the ready panel rather than sitting under it:
      // once it is running there is nothing left to press.
      const counting = typeof state.starts_in === "number"
      // The server rounds the remaining seconds *up*, so re-anchoring on every
      // poll could only ever push the deadline later and make a five-second
      // countdown take six. Its answer is taken when it is earlier than ours,
      // never when it is later.
      if (counting) {
        const next = Date.now() + state.starts_in * 1000
        if (this.startsAt === null || next < this.startsAt) this.startsAt = next
      } else {
        this.startsAt = null
      }
      this.readyPanelTarget.hidden = counting
      this.countdownTarget.hidden = !counting
      this.tickCountdown()
      return
    }

    this.update(this.yourScoreTarget, state.you.score)
    this.update(this.yourAnsweredTarget, state.you.answered)
    if (state.opponent) {
      this.update(this.opponentScoreTarget, state.opponent.score)
      this.update(this.opponentAnsweredTarget, state.opponent.answered)
    }
  }

  markReady(target, ready) {
    if (!target) return

    target.textContent = ready ? target.dataset.readyLabel : target.dataset.waitingLabel
    target.classList.toggle("is-ready", Boolean(ready))
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
