import { Controller } from "@hotwired/stimulus"

// The topic tree's highlight. Choosing a topic replaces only the side panel's
// frame, so the row that says which topic the panel is about has to move here.
export default class extends Controller {
  select(event) {
    const id = event.currentTarget.dataset.topicId
    this.element.querySelectorAll(".is-selected").forEach((row) => row.classList.remove("is-selected"))
    this.element.querySelectorAll(`.topic-row[data-topic-id="${id}"]`).forEach((row) => row.classList.add("is-selected"))
  }
}
