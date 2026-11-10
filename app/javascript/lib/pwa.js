// Registers the service worker (app/views/pwa/service-worker.js), which makes
// the app installable, keeps digested assets across a deploy and shows
// /offline.html when a page cannot be reached. A Turbo Drive visit that fails
// on the network needs nothing extra: Turbo's BrowserAdapter answers it with a
// full navigation to the same URL, which the worker does answer.
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker.js", { scope: "/" }).catch(() => {
      // Private windows and some embedded browsers refuse; the app works without it.
    })
  }, { once: true })
}
