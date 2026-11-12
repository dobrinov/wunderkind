import { Controller } from "@hotwired/stimulus"

// „Десетични дроби": the digits 3, 4, 7 in seven places — thousands to
// thousandths — with the decimal point fixed between the ones and the tenths.
// Multiplying by 10 moves every digit one place left, dividing one place
// right; the point never moves. Places a number needs but the digits do not
// reach are shown as faint zeros.
const DIGITS = [3, 4, 7]
const ONES = 3            // the index of the ones' place among the seven
const PLACES = 7
const START = 3           // where the first digit starts: 3,47

export default class extends Controller {
  static targets = ["cell", "value", "times", "divide", "note"]
  static values = { copy: Object }

  connect() {
    this.reset()
  }

  reset() {
    this.first = START
    this.render(this.copyValue.start)
  }

  times() {
    if (this.first === 0) return
    this.first -= 1
    this.render(this.copyValue.times_note)
  }

  divide() {
    if (this.first + DIGITS.length === PLACES) return
    this.first += 1
    this.render(this.copyValue.divide_note)
  }

  render(note) {
    const copy = this.copyValue
    const last = this.first + DIGITS.length - 1

    this.cellTargets.forEach((cell, place) => {
      const digit = DIGITS[place - this.first]
      // A zero that holds a place: between the digits and the ones, or the
      // ones' place itself when the digits are all after the point.
      const filler = digit === undefined && ((place > last && place <= ONES) || (place === ONES && this.first > ONES))
      cell.textContent = digit ?? (filler ? "0" : "")
      cell.classList.toggle("text-ink-400", filler)
      cell.classList.toggle("text-ink-900", !filler)
    })

    const whole = this.cellTargets.slice(0, ONES + 1).map((cell) => cell.textContent).join("").replace(/^0+(?=\d)/, "") || "0"
    const part = this.cellTargets.slice(ONES + 1).map((cell) => cell.textContent || "0").join("").replace(/0+$/, "")
    const number = part ? `${whole}${copy.point}${part}` : whole
    const fraction = part ? ` = ${Number(DIGITS.join(""))}/${10 ** part.length}` : ""

    this.valueTarget.textContent = number + fraction
    this.timesTarget.disabled = this.first === 0
    this.divideTarget.disabled = last === PLACES - 1
    this.noteTarget.textContent = note
  }
}
