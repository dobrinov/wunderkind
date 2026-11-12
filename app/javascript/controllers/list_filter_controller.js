import { Controller } from "@hotwired/stimulus"

// A search box over a list that is already on the page — the formula sheets
// (formulas/index) and the hub's topic directory (curriculum/index). Typing
// only hides the items whose `data-text` does not hold the query, then the
// groups left with no item, and says so when nothing is left.
export default class extends Controller {
  static targets = ["query", "item", "group", "empty"]

  filter() {
    const query = this.queryTarget.value.trim().toLowerCase()

    for (const item of this.itemTargets) {
      item.hidden = query !== "" && !item.dataset.text.includes(query)
    }

    let shown = 0
    for (const group of this.groupTargets) {
      const visible = group.querySelectorAll("[data-list-filter-target='item']:not([hidden])").length
      group.hidden = visible === 0
      shown += visible
    }

    this.emptyTarget.hidden = shown > 0
  }
}
