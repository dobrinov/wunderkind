// What a page does when the server it came from is gone for a moment — which,
// on this app, is a deploy: deploy.sh replaces the one container, Caddy answers
// 502 until the new one is healthy, and the new image holds only the new
// release's digested files. Trace saw both halves on 8 November: answers posted
// into the restart, and pages loaded just before it asking for chunks that no
// longer exist.
//
// The key is shared with the inline handler in shared/_head, which covers the
// case this module cannot: application.js itself failing to load.
const RELOADED_AT = "wk-reloaded-at"
const RELOAD_GUARD_MS = 30_000

// Resolves once a GET of `url` comes back 2xx, or after `timeout` whatever
// happened — the caller reloads either way, and a page that is still down then
// is better shown than a spinner that never ends.
export async function whenServerAnswers(url = window.location.href, { interval = 2000, timeout = 60_000 } = {}) {
  const deadline = Date.now() + timeout

  while (Date.now() < deadline) {
    try {
      const response = await fetch(url, { method: "GET", cache: "no-store", credentials: "same-origin", redirect: "manual" })
      // An opaque redirect (a signed-out session, a finished assignment) is the
      // app answering, which is all this waits for.
      if (response.ok || response.type === "opaqueredirect") return true
    } catch {
      // Still restarting.
    }
    await new Promise((resolve) => setTimeout(resolve, interval))
  }
  return false
}

// Reloads the page unless it was reloaded for this reason in the last half
// minute, so a file that is missing for some other reason cannot loop.
export function reloadOnce() {
  try {
    const last = Number(sessionStorage.getItem(RELOADED_AT)) || 0
    if (Date.now() - last < RELOAD_GUARD_MS) return false
    sessionStorage.setItem(RELOADED_AT, String(Date.now()))
  } catch {
    // No storage means no guard, and no guard means no reload.
    return false
  }
  window.location.reload()
  return true
}
