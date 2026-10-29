// Sending a custom event to Plausible and to Trace, from the client and from
// the server.
//
// Pageviews need nothing from this file: the script hooks history.pushState,
// which is what Turbo Drive navigates with, so a Turbo visit is counted like a
// full load. What is here is the handful of *named* moments — a signup, a
// finished session, a duel result — that the dashboard turns into goals.
//
// Two ways in. A controller that knows the moment happened queues it with
// `track` (see concerns/tracked_events.rb) and it arrives as a meta tag on the
// next page, which is the right shape for anything that ends in a redirect. A
// moment the server never sees a request for — the duel clock running out under
// a player who is just watching — is sent from the browser instead, by
// importing `track` from here.
//
// Every path through this file is a no-op when window.plausible is missing,
// which is development, an admin session, and every visitor running a blocker.
// None of those is an error worth a line in the console. The same goes for
// window.trace, which shared/_analytics renders under the same switch.

// Trace's name for an event is its key in Analytics::EVENTS, which is the
// Plausible name lowercased with underscores — "Session Started" is
// session_started. trace.json lists the events under those keys, and the
// request spec holds the two spellings together.
function traceName(name) {
  return name.toLowerCase().replace(/\s+/g, "_")
}

// Trace's stub, like Plausible's, queues calls until d.js has landed. `flush`
// is for the caller that is about to reload: Trace batches what it sends, and
// a batch still waiting when the page goes is a batch that never arrives.
function sendToTrace(name, props, { flush = false } = {}) {
  const trace = window.trace
  if (typeof trace?.track !== "function") return

  try {
    trace.track(traceName(name), props)
    if (flush && typeof trace.flush === "function") trace.flush()
  } catch {
    // Analytics is never worth breaking a page for.
  }
}

// Plausible's own stub defines window.plausible synchronously in <head>, ahead
// of the async script, and queues anything sent before the script has landed.
// So there is no readiness to wait for here — only the case where the script
// was never rendered at all.
export function track(name, props = {}) {
  sendToTrace(name, props)
  if (typeof window.plausible !== "function") return

  try {
    window.plausible(name, { props: props })
  } catch {
    // Analytics is never worth breaking a page for.
  }
}

// Sends an event and then runs `done` — on Plausible's own callback if it
// comes, on a short timer if it does not. For the one caller that navigates
// away in the same breath as it counts something: a request cancelled by the
// reload that follows it is an event that never happened, and "how many duels
// actually get finished" is not a number worth quietly understating. The timer
// is the whole safety net — a blocked or missing script never calls back, and a
// screen that waits forever for analytics is a worse bug than a lost event.
export function trackThen(name, props, done, { timeout = 400 } = {}) {
  let finished = false
  const once = () => {
    if (finished) return
    finished = true
    done()
  }

  setTimeout(once, timeout)

  sendToTrace(name, props, { flush: true })
  if (typeof window.plausible !== "function") return once()

  try {
    window.plausible(name, { props: props, callback: once })
  } catch {
    once()
  }
}

// The server-queued event, written by shared/_analytics. Turbo swaps meta tags
// on every visit, so this is the current page's event and never a stale one.
function queuedEvent() {
  const meta = document.querySelector('meta[name="analytics-event"]')
  if (meta === null) return null

  try {
    const event = JSON.parse(meta.content)

    return typeof event?.name === "string" ? event : null
  } catch {
    return null
  }
}

// Who is signed in, or nobody: shared/_analytics writes a keyed hash of the
// user's id into the page, and Trace counts the session under it. Read on every
// visit, so the hash goes as soon as someone signs out.
function identifyToTrace() {
  const trace = window.trace
  if (typeof trace?.identify !== "function") return

  const meta = document.querySelector('meta[name="trace-identity"]')
  try {
    trace.identify(meta === null ? null : meta.content)
  } catch {
    // Analytics is never worth breaking a page for.
  }
}

// turbo:load rather than DOMContentLoaded: it fires on the first load *and* on
// every Turbo visit, and Turbo has already pushed the new URL by then, so the
// event is attributed to the page it actually happened on.
document.addEventListener("turbo:load", () => {
  identifyToTrace()
  const event = queuedEvent()
  if (event) track(event.name, event.props || {})
})
