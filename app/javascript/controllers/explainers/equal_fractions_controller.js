import { Controller } from "@hotwired/stimulus"
import { mathNode } from "../../lib/frac"

// „Какво е дроб?": half a bar, and under it the same bar with each half cut
// into m pieces. The coloured length never changes; only the count does —
// 1/2 = m/2m, which is what equal fractions are.
export default class extends Controller {
  static targets = ["slider", "times", "bar", "fraction", "note"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  cut() {
    this.render()
  }

  render() {
    const m = Number(this.sliderTarget.value)
    const parts = 2 * m
    const copy = this.copyValue

    this.timesTarget.textContent = m === 1 ? copy.times_one : copy.times.replace("%{m}", m)
    this.barTarget.style.gridTemplateColumns = `repeat(${parts}, minmax(0, 1fr))`
    this.barTarget.setAttribute("aria-label", copy.bottom_bar.replace("%{parts}", parts).replace("%{m}", m))
    this.barTarget.replaceChildren(...Array.from({ length: parts }, (_, i) => {
      const piece = document.createElement("span")
      const rounded = i === 0 ? "rounded-l-[7px]" : i === parts - 1 ? "rounded-r-[7px]" : ""
      piece.className = `h-14 ${rounded} ${i < m ? "bg-primary-400" : "bg-white"}`
      return piece
    }))
    this.fractionTarget.replaceChildren(mathNode(`${m}/${parts}`))
    this.noteTarget.textContent = m === 1 ? copy.note_one : copy.note.replaceAll("%{m}", m)
  }
}
