import { Controller } from "@hotwired/stimulus"

// „НОД и НОК": two numbers from 2 to 12 and four rows of chips — the
// multiples of each up to a · b, then the divisors of each. Going up to a · b
// is what guarantees a shared multiple is always on screen (the product is
// one), and it keeps every row to twelve chips at most. Shared numbers are
// ringed; the first shared multiple carries the tag НОК and the largest
// shared divisor НОД, so neither depends on colour to be found.
const CHIP = "inline-flex h-9 min-w-9 items-center justify-center gap-1 rounded-[10px] px-2 text-ui font-black tabular-nums"
const PLAIN = "bg-white text-ink-700 ring-1 ring-ink-200"
const SHARED = "bg-primary-100 text-primary-900 ring-2 ring-primary-600"
const MARKED = "bg-primary-600 text-white ring-2 ring-primary-600"

export default class extends Controller {
  static targets = ["a", "b", "aOut", "bOut", "figure", "result", "check"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const a = Number(this.aTarget.value)
    const b = Number(this.bTarget.value)
    const product = a * b

    const multiples = (n) => Array.from({ length: product / n }, (_, i) => n * (i + 1))
    const divisors = (n) => Array.from({ length: n }, (_, i) => i + 1).filter((d) => n % d === 0)
    const lcm = multiples(a).find((m) => m % b === 0)
    const gcd = divisors(a).filter((d) => b % d === 0).pop()

    const fill = (text) => text.replaceAll("%{a}", a).replaceAll("%{b}", b).replaceAll("%{product}", product)
      .replaceAll("%{lcm}", lcm).replaceAll("%{gcd}", gcd)

    this.aOutTarget.textContent = a
    this.bOutTarget.textContent = b
    this.figureTarget.setAttribute("aria-label", fill(copy.figure))
    this.figureTarget.replaceChildren(
      this.row(copy.multiples.replaceAll("%{n}", a), multiples(a), (m) => m % b === 0, lcm, copy.lcm),
      this.row(copy.multiples.replaceAll("%{n}", b), multiples(b), (m) => m % a === 0, lcm, copy.lcm),
      this.row(copy.divisors.replaceAll("%{n}", a), divisors(a), (d) => b % d === 0, gcd, copy.gcd),
      this.row(copy.divisors.replaceAll("%{n}", b), divisors(b), (d) => a % d === 0, gcd, copy.gcd)
    )
    this.resultTarget.textContent = fill(copy.result)
    this.checkTarget.textContent = fill(copy.check)
  }

  // One labelled row of chips: `shared` says which are in the other row too,
  // and the one equal to `marked` carries `tag`.
  row(label, numbers, shared, marked, tag) {
    const row = document.createElement("div")
    row.className = "flex flex-col gap-1.5"
    const title = document.createElement("p")
    title.className = "text-meta font-black text-ink-600"
    title.textContent = label
    const chips = document.createElement("div")
    chips.className = "flex flex-wrap gap-1.5"

    for (const number of numbers) {
      const chip = document.createElement("span")
      chip.className = `${CHIP} ${number === marked ? MARKED : shared(number) ? SHARED : PLAIN}`
      chip.textContent = number
      if (number === marked) {
        const badge = document.createElement("span")
        badge.className = "text-micro font-black uppercase"
        badge.textContent = tag
        chip.append(badge)
      }
      chips.append(chip)
    }
    row.append(title, chips)
    return row
  }
}
