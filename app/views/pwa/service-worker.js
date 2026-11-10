// The service worker, served at /service-worker.js by Rails::PwaController and
// registered by app/javascript/lib/pwa.js. It makes the app installable and
// does two things beyond that, deliberately no more:
//
// 1. Digested assets (/assets/name-<hash>.css, esbuild's *.digested.js chunks)
//    come from a cache first. Their names change whenever their content does,
//    so a cached copy can never be stale — and a page from the release before a
//    deploy can still find the chunks the new image no longer has, which is the
//    failure lib/recover.js and wkAssetFailed() otherwise reload their way out of.
//
// 2. A page navigation that fails for want of a network gets /offline.html
//    instead of the browser's dinosaur.
//
// HTML is never cached: nearly every page is one person's (a session, a streak,
// an impersonated child), and a stale one shown to the wrong reader is worse
// than an offline notice. POSTs, Turbo fetches, the duel's polling and every
// cross-origin request (fonts, Plausible, Sentry) pass through untouched.
//
// Bump VERSION when offline.html or this strategy changes: a changed byte here
// is what makes browsers install the new worker.
const VERSION = "v1"
const PAGES = `wk-pages-${VERSION}`
const ASSETS = "wk-assets"
const OFFLINE_URL = "/offline.html"
// The newest this many assets are kept; a release adds a dozen, so this holds
// a few releases' worth without growing forever.
const MAX_ASSETS = 120

const DIGESTED = /^\/assets\/.+(-[0-9a-f]{7,}\.[a-z0-9]+|\.digested\.js)$/

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(PAGES)
      .then((cache) => cache.addAll([ new Request(OFFLINE_URL, { cache: "reload" }) ]))
      .then(() => self.skipWaiting())
  )
})

self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys()
    await Promise.all(
      names.filter((name) => name.startsWith("wk-pages-") && name !== PAGES).map((name) => caches.delete(name))
    )
    if (self.registration.navigationPreload) await self.registration.navigationPreload.enable()
    await self.clients.claim()
  })())
})

self.addEventListener("fetch", (event) => {
  const request = event.request
  if (request.method !== "GET") return

  const url = new URL(request.url)
  if (url.origin !== self.location.origin) return

  if (request.mode === "navigate") {
    event.respondWith(navigation(event))
  } else if (DIGESTED.test(url.pathname)) {
    event.respondWith(digestedAsset(event))
  }
})

async function navigation(event) {
  try {
    const preloaded = await event.preloadResponse
    if (preloaded) return preloaded
    return await fetch(event.request)
  } catch {
    const offline = await caches.match(OFFLINE_URL, { cacheName: PAGES })
    return offline || Response.error()
  }
}

async function digestedAsset(event) {
  const cache = await caches.open(ASSETS)
  const cached = await cache.match(event.request)
  if (cached) return cached

  const response = await fetch(event.request)
  if (response.ok) {
    event.waitUntil(cache.put(event.request, response.clone()).then(() => trim(cache)))
  }
  return response
}

// Cache keys come back in insertion order, so the oldest go first.
async function trim(cache) {
  const keys = await cache.keys()
  const excess = keys.length - MAX_ASSETS
  for (let i = 0; i < excess; i++) await cache.delete(keys[i])
}
