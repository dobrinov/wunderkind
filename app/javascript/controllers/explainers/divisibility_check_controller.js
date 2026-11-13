import { Controller } from "@hotwired/stimulus"

// „Признаци за делимост": a number of up to four digits, each digit stepped
// with its own + and −, and six divisors marked ✓ or ✕ for it. Stepping one
// digit at a time is the point: change the ones and only 2, 5 and 10 react to
// the digit itself, while 3 and 9 follow the digit sum. The chosen divisor's
// rule is written out for the number on screen. The number never reaches 0,
// which every rule would call divisible and no pupil would call a number.
const DIVISORS = [2, 3, 4, 5, 9, 10]

export default class extends Controller {
  static targets = ["digit", "more", "less", "chip", "note"]
  static values = { copy: Object }

  connect() {
    // The article's own example: 471, read against the rule for 3.
    this.digits = [0, 4, 7, 1]
    this.divisor = 3
    this.render()
  }

  more({ params: { place } }) {
    if (this.digits[place] >= 9) return
    this.digits[place] += 1
    this.render()
    this.keepFocus(this.moreTargets[place], this.lessTargets[place])
  }

  less({ params: { place } }) {
    if (!this.canLower(place)) return
    this.digits[place] -= 1
    this.render()
    this.keepFocus(this.lessTargets[place], this.moreTargets[place])
  }

  // A key that has just disabled itself would drop the keyboard's place, so
  // focus moves to the digit's other key — or, when that one is at its limit
  // too (a 9 that is the only digit left), to the chosen divisor.
  keepFocus(pressed, other) {
    if (!pressed.disabled) return
    const next = other.disabled ? this.chipTargets[DIVISORS.indexOf(this.divisor)] : other
    next.focus()
  }

  pick({ params: { divisor } }) {
    this.divisor = divisor
    this.render()
  }

  // A digit can go down unless it is 0 already or is the last thing keeping
  // the number above zero.
  canLower(place) {
    return this.digits[place] > 0 && this.digits.reduce((sum, digit) => sum + digit, 0) > 1
  }

  render() {
    const copy = this.copyValue
    const n = Number(this.digits.join(""))
    const shown = this.group(n)
    const lead = this.digits.findIndex((digit) => digit > 0)

    this.digitTargets.forEach((cell, place) => {
      cell.textContent = this.digits[place]
      // Zeros in front of the number are places, not digits of it.
      cell.classList.toggle("text-ink-400", place < lead)
      cell.classList.toggle("text-ink-900", place >= lead)
    })
    this.moreTargets.forEach((button, place) => { button.disabled = this.digits[place] >= 9 })
    this.lessTargets.forEach((button, place) => { button.disabled = !this.canLower(place) })

    this.chipTargets.forEach((chip, index) => {
      const d = DIVISORS[index]
      const yes = n % d === 0
      const chosen = d === this.divisor
      chip.textContent = `${d} ${yes ? "✓" : "✕"}`
      chip.setAttribute("aria-pressed", chosen)
      chip.setAttribute("aria-label", (yes ? copy.chip_yes : copy.chip_no).replaceAll("%{n}", shown).replaceAll("%{d}", d))
      chip.classList.toggle("bg-green-100", yes && !chosen)
      chip.classList.toggle("text-green-800", yes && !chosen)
      chip.classList.toggle("text-ink-500", !yes && !chosen)
    })

    this.noteTarget.textContent = this.explain(n, this.divisor)
  }

  // 9999 as „9 999" / "9,999": thousands grouped the way the locale writes them.
  group(n) {
    return n < 1000 ? String(n) : `${Math.floor(n / 1000)}${this.copyValue.group}${String(n % 1000).padStart(3, "0")}`
  }

  // The chosen divisor's rule, applied to n.
  explain(n, d) {
    const copy = this.copyValue
    const yes = n % d === 0
    const digits = String(n).split("")
    const sum = digits.reduce((total, digit) => total + Number(digit), 0)
    const work = digits.length > 1 ? `${digits.join(" + ")} = ${sum}` : String(sum)

    let key
    if (d === 2) key = "two"
    else if (d === 5) key = "five"
    else if (d === 10) key = "ten"
    else if (d === 4) key = n < 100 ? "four_short" : "four"
    else key = "sum"

    return copy[`${key}_${yes ? "yes" : "no"}`]
      .replaceAll("%{n}", this.group(n)).replaceAll("%{d}", d).replaceAll("%{last}", n % 10)
      .replaceAll("%{work}", work).replaceAll("%{sum}", sum)
      .replaceAll("%{tail_n}", n % 100).replaceAll("%{tail}", String(n).slice(-2))
      .replaceAll("%{q}", n / 4)
  }
}
