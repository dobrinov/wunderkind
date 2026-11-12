import { Controller } from "@hotwired/stimulus"

// „Разряди и големи числа": a number up to 9 999 as four digits, each with
// its own + and − and a little grid of counters. The state is the number
// itself, so a + on a column that already holds 9 is simply „add one of this
// place" — the digit rolls to 0 and the column on its left gains one, which
// is the exchange the article is about; a − on an empty column takes one
// from the left the same way. The note names every exchange a press caused
// (999 + 1 causes three). A press that would leave 0–9 999 is switched off —
// with a line saying why when it is a +, since „+ on a 9 carries" stops being
// true at the top — and a button that switches itself off hands the
// keyboard's focus to the other button of its column, which never is off at
// the same time.
const NAMES = ["ones", "tens", "hundreds", "thousands"]   // by power of ten
const START = 3456
const MAX = 9999

export default class extends Controller {
  static targets = ["plus", "minus", "digit", "counter", "value", "note", "limit"]
  static values = { copy: Object }

  connect() {
    // The article's own example first: 3 456.
    this.number = START
    this.render(this.copyValue.start)
  }

  plus(event) {
    const power = Number(event.params.power)
    if (this.number + 10 ** power > MAX) return
    // Every column from this one leftwards that stands at 9 hands ten on.
    const notes = []
    for (let place = power; this.digit(place) === 9; place++) notes.push(this.copyValue[`carry_${NAMES[place]}`])
    this.number += 10 ** power
    this.render(notes.join(" ") || this.plain(power))
    if (event.currentTarget?.disabled) this.minusTargets[3 - power].focus()
  }

  minus(event) {
    const power = Number(event.params.power)
    if (this.number - 10 ** power < 0) return
    // The nearest column on the left that has something is broken up, one
    // place at a time, down to this one.
    let from = power
    while (this.digit(from) === 0) from++
    const notes = []
    for (let place = from - 1; place >= power; place--) notes.push(this.copyValue[`borrow_${NAMES[place]}`])
    this.number -= 10 ** power
    this.render(notes.join(" ") || this.plain(power))
    if (event.currentTarget?.disabled) this.plusTargets[3 - power].focus()
  }

  digit(power) {
    return Math.floor(this.number / 10 ** power) % 10
  }

  // What the digit in this column is worth now.
  plain(power) {
    const copy = this.copyValue
    const digit = this.digit(power)
    return copy.plain.replaceAll("%{digit}", digit).replaceAll("%{place}", copy[`of_${NAMES[power]}`])
      .replaceAll("%{worth}", this.format(digit * 10 ** power))
  }

  // 3456 as „3 456" or "3,456".
  format(number) {
    return String(number).replace(/\B(?=(\d{3})+(?!\d))/g, this.copyValue.group)
  }

  render(note) {
    // The columns stand thousands first; the powers run the other way.
    this.digitTargets.forEach((cell, column) => { cell.textContent = this.digit(3 - column) })
    this.counterTargets.forEach((counter, index) => {
      const on = index % 9 < this.digit(3 - Math.floor(index / 9))
      counter.classList.toggle("bg-primary-600", on)
      counter.classList.toggle("bg-ink-200", !on)
    })
    this.plusTargets.forEach((button, column) => { button.disabled = this.number + 10 ** (3 - column) > MAX })
    this.minusTargets.forEach((button, column) => { button.disabled = this.number - 10 ** (3 - column) < 0 })
    this.limitTarget.hidden = !this.plusTargets.some((button) => button.disabled)

    const parts = [3, 2, 1, 0].map((power) => this.digit(power) * 10 ** power).filter((part) => part > 0).map((part) => this.format(part))
    const number = this.format(this.number)
    this.valueTarget.textContent = parts.length > 1 ? `${number} = ${parts.join(" + ")}` : number
    this.noteTarget.textContent = note
  }
}
