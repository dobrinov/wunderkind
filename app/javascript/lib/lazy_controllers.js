import { reloadOnce, whenServerAnswers } from "./recover"

// Registers a Stimulus controller only when an element on the page names it,
// so a controller's dependencies stay in their own chunk until then. Stimulus
// connects the elements already on the page as soon as one is registered.
export function registerLazy(application, loaders) {
  const pending = new Map(Object.entries(loaders))

  const load = (identifier) => {
    const loader = pending.get(identifier)
    if (!loader) return
    pending.delete(identifier)
    loader()
      .then((module) => application.register(identifier, module.default))
      .catch((error) => {
        // A failed fetch is a dropped connection or, more often, a deploy: the
        // chunk this bundle imports is gone from the new image, and every later
        // retry from this document asks for the same dead name — the next
        // Turbo visit included, because a cached snapshot or a frame never
        // compares the tracked assets. Only a reload into the new release
        // fixes it, once the server is answering again.
        pending.set(identifier, loader)
        console.error(error)
        whenServerAnswers().then((answering) => answering && reloadOnce())
      })
  }

  const scan = (root) => {
    if (pending.size === 0 || !(root instanceof Element)) return
    const elements = [root, ...root.querySelectorAll("[data-controller]")]
    for (const element of elements) {
      for (const identifier of (element.getAttribute("data-controller") || "").split(/\s+/)) {
        load(identifier)
      }
    }
  }

  new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      if (mutation.type === "attributes") scan(mutation.target)
      else mutation.addedNodes.forEach(scan)
    }
  }).observe(document.documentElement, {
    childList: true, subtree: true, attributes: true, attributeFilter: ["data-controller"]
  })
  scan(document.documentElement)
}
