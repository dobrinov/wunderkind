import { Controller } from "@hotwired/stimulus"

// The badge wall on the profile: filter chips, and a cap on how many tiles a
// phone shows at once.
//
// Both live here rather than in two controllers because they interact — which
// tiles are "the first six" depends on which filter is active, so a CSS-only
// nth-child cap would show the wrong six as soon as you filtered.
export default class extends Controller {
  static targets = ["tile", "chip", "expander"]
  static values = {
    filter: { type: String, default: "all" },
    expanded: { type: Boolean, default: false },
    cap: { type: Number, default: 6 }
  }

  connect() {
    // The cap is a phone concern only; a desktop grid has room for all of them.
    this.wide = window.matchMedia("(min-width: 640px)")
    this.onResize = () => this.render()
    this.wide.addEventListener("change", this.onResize)
    this.render()
  }

  disconnect() {
    this.wide.removeEventListener("change", this.onResize)
  }

  filter(event) {
    this.filterValue = event.params.filter
    this.expandedValue = false
  }

  toggle() {
    this.expandedValue = !this.expandedValue
  }

  filterValueChanged() {
    if (this.wide) this.render()
  }

  expandedValueChanged() {
    if (this.wide) this.render()
  }

  render() {
    const capped = !this.wide.matches && !this.expandedValue
    let shown = 0
    let matching = 0

    for (const tile of this.tileTargets) {
      const matches = this.filterValue === "all" || tile.dataset.state === this.filterValue
      if (matches) matching += 1

      const visible = matches && (!capped || shown < this.capValue)
      if (visible) shown += 1
      tile.classList.toggle("hidden", !visible)
    }

    for (const chip of this.chipTargets) {
      const active = chip.dataset.filter === this.filterValue
      chip.classList.toggle("bg-white", active)
      chip.classList.toggle("text-primary-700", active)
      chip.classList.toggle("shadow-xs", active)
      chip.classList.toggle("text-gray-500", !active)
    }

    if (this.hasExpanderTarget) {
      const hidden = matching - shown
      this.expanderTarget.classList.toggle("hidden", hidden === 0 && !this.expandedValue)
      this.expanderTarget.textContent = this.expandedValue
        ? this.expanderTarget.dataset.less
        : this.expanderTarget.dataset.more.replace("%{count}", matching)
    }
  }
}
