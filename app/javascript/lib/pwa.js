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

// Chromium offers installing once per page load, with an event that can come
// before the „Аз" row that uses it is on the page — and Turbo keeps this one
// page load across visits — so it is kept here for install_controller.js. Not
// preventDefault()ed: Chrome's own install banner still shows to everyone who
// never opens „Аз".
let installPrompt = null

window.addEventListener("beforeinstallprompt", (event) => {
  installPrompt = event
  document.dispatchEvent(new CustomEvent("wk:installable"))
})

window.addEventListener("appinstalled", () => {
  installPrompt = null
  document.dispatchEvent(new CustomEvent("wk:installed"))
})

export function pendingInstallPrompt() {
  return installPrompt
}

// A prompt can be shown only once; after that Chromium sends a fresh event if
// installing is still possible.
export function consumeInstallPrompt() {
  const prompt = installPrompt
  installPrompt = null
  return prompt
}

export function isInstalled() {
  return window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
}

// iPadOS reports itself as a Mac; a Mac has no touch points.
export function appleTouchDevice() {
  const ua = navigator.userAgent
  if (/iPad/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1)) return "ipad"
  if (/iPhone|iPod/.test(ua)) return "iphone"
  return null
}
