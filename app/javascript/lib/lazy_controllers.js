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
        // A failed fetch (a deploy swapped the chunks, a dropped connection)
        // should be retried by the next page that needs it.
        pending.set(identifier, loader)
        console.error(error)
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
