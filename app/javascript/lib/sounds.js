// The two answer cues, synthesized rather than shipped as audio files.
//
// Two reasons for Web Audio over an <audio> tag with an mp3. The cues are two
// sine notes each — a file would be a binary blob in the repo that nobody can
// read a diff of, for something this file says in a table. And the autoplay
// policy is identical for both APIs, so a file would buy nothing there either:
// what actually decides whether a cue is heard is *which document* plays it.
//
// That is the constraint the whole feature is built around. Chrome hands the
// new document the previous one's user activation, so a chime on the feedback
// page works there; WebKit and Firefox do not, and an AudioContext created on a
// freshly loaded page stays suspended with its resume() promise pending
// forever. So nothing here is ever played on page load: `unlock` runs inside
// the click that submits an answer, and `play` runs on the same page a moment
// later, when the server has said whether the answer was right. See
// answer_form_controller.js, which owns that sequence.
//
// A cue is a list of notes: hz, when it starts, how long it rings.
const CUES = {
  // Rising, and a perfect fifth apart, because that is the interval that reads
  // as resolved rather than merely loud.
  correct: {
    type: "sine",
    gain: 0.16,
    notes: [
      { hz: 659.25, at: 0, ms: 120 },
      { hz: 987.77, at: 70, ms: 170 }
    ]
  },
  // Falling and quieter, on a triangle wave: a wrong answer in a children's
  // app gets a note that says "not that one", never a buzzer that says "no".
  wrong: {
    type: "triangle",
    gain: 0.11,
    notes: [
      { hz: 392.00, at: 0, ms: 140 },
      { hz: 311.13, at: 95, ms: 190 }
    ]
  }
}

// How long the cue rings, so the caller knows how long to hold the page.
export function cueDuration(name) {
  const cue = CUES[name]
  if (!cue) return 0

  return Math.max(...cue.notes.map((note) => note.at + note.ms))
}

let context = null
let enabled = null

function preference() {
  const meta = document.querySelector('meta[name="sound-effects"]')

  return meta !== null && meta.content === "true"
}

export function soundEnabled() {
  if (enabled === null) enabled = preference()

  return enabled
}

// Set by the speaker button the moment it is pressed, so the next answer is
// silent (or audible) without waiting on the request that saves the choice.
export function setSoundEnabled(value) {
  enabled = value
}

// Must be called from inside a trusted user gesture — a click, a keypress —
// or the context is created suspended and never starts. Cheap and idempotent:
// the answer form calls it on every submit.
export function unlock({ force = false } = {}) {
  if (!force && !soundEnabled()) return

  const Context = window.AudioContext || window.webkitAudioContext
  if (!Context) return

  try {
    if (context === null) context = new Context()
    if (context.state === "suspended") context.resume().catch(() => {})
  } catch {
    context = null // No audio on this device. Everything below turns into a no-op.
  }
}

// Plays a cue whatever the student's preference says, for the demo on
// /design-system: a page whose whole job is to let you hear the two sounds is
// no use if it obeys the switch that silences them.
export function preview(name) {
  return play(name, { force: true })
}

// Returns the milliseconds of sound actually started, so a caller that wants to
// wait for it knows whether there is anything to wait for. Zero means the cue
// was muted, unknown, or blocked by the browser — all of which are silence, and
// none of which are worth delaying a page for.
export function play(name, { force = false } = {}) {
  if (!force && !soundEnabled()) return 0

  const cue = CUES[name]
  if (!cue) return 0

  unlock({ force: force })
  if (context === null || context.state !== "running") return 0

  try {
    cue.notes.forEach((note) => {
      const start = context.currentTime + note.at / 1000
      const stop = start + note.ms / 1000

      const oscillator = context.createOscillator()
      oscillator.type = cue.type
      oscillator.frequency.value = note.hz

      // A ramped envelope, not a bare start/stop: an oscillator switched on at
      // full gain clicks, and the click is louder than the note.
      const envelope = context.createGain()
      envelope.gain.setValueAtTime(0.0001, start)
      envelope.gain.exponentialRampToValueAtTime(cue.gain, start + 0.012)
      envelope.gain.exponentialRampToValueAtTime(0.0001, stop)

      oscillator.connect(envelope).connect(context.destination)
      oscillator.start(start)
      oscillator.stop(stop + 0.02)
    })
  } catch {
    return 0
  }

  return cueDuration(name)
}
