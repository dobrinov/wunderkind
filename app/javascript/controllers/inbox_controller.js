import { Controller } from "@hotwired/stimulus"

// The admin inbox. A row opens its ticket in the pane beside the list (a
// turbo-frame), which leaves the list itself as it was — so the highlight
// moves here, on the click, rather than with a page the list never reloads.
export default class extends Controller {
  static targets = ["row"]

  select(event) {
    this.rowTargets.forEach((row) => row.removeAttribute("aria-current"))
    event.currentTarget.setAttribute("aria-current", "true")
  }
}
