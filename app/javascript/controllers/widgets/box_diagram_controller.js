import { Controller } from "@hotwired/stimulus"

// Box-diagram widget: a picture of boxes joined by arrows (drawn server-side by
// widgets/_box_diagram), the empty boxes written into in place. It replaced a
// paragraph describing a first-grade paper's arrows and six questions over it.
// {values: {boxId: text}} is the answer state, submitted once every box has
// something in it.
export default class extends Controller {
  static targets = ["box", "hidden"]

  connect() {
    this.sync()
  }

  sync() {
    const values = Object.fromEntries(this.boxTargets.map((input) => [ input.dataset.box, input.value.trim() ]))
    const complete = this.boxTargets.length > 0 && Object.values(values).every((value) => value !== "")
    this.hiddenTarget.value = complete ? JSON.stringify({ values }) : ""
  }
}
