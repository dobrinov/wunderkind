import { Controller } from "@hotwired/stimulus"

// „Как се смятат проценти": a number laid out as a hundred squares, each 1%
// of it. The percentage shades that many squares, and the answer is read off
// the picture: what one square is worth, times how many are shaded.
export default class extends Controller {
  static targets = ["whole", "percent", "wholeOut", "percentOut", "grid", "cell", "one", "result"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const whole = Number(this.wholeTarget.value)
    const percent = Number(this.percentTarget.value)
    // Whole numbers of tenths, so 1% of 250 is 2,5 and never 2,5000000004.
    const num = (value) => String(Math.round(value * 100) / 100).replace(".", copy.point)
    const fill = (text) => text.replaceAll("%{whole}", whole).replaceAll("%{percent}", percent)
      .replaceAll("%{one}", num(whole / 100)).replaceAll("%{value}", num((whole * percent) / 100))

    this.wholeOutTarget.textContent = whole
    this.percentOutTarget.textContent = `${percent}%`
    this.cellTargets.forEach((cell, index) => {
      const on = index < percent
      cell.classList.toggle("bg-primary-600", on)
      cell.classList.toggle("bg-ink-200", !on)
    })
    this.gridTarget.setAttribute("aria-label", fill(copy.figure))
    this.oneTarget.textContent = fill(copy.one)
    this.resultTarget.textContent = fill(copy.result)
  }
}
