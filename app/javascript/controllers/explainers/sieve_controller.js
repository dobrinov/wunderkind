import { Controller } from "@hotwired/stimulus"

// The sieve of Eratosthenes up to 100. Each button crosses out the multiples
// of one prime — never the prime itself — and once 2, 3, 5 and 7 are done the
// 25 numbers still standing are every prime there is below 100.
const PRIMES = [ 2, 3, 5, 7 ]

export default class extends Controller {
  static targets = ["key", "cell", "note"]
  static values = { copy: Object }

  connect() {
    this.struck = new Set()
    this.render()
  }

  strike({ params: { prime } }) {
    this.struck.add(prime)
    this.render()
  }

  reset() {
    this.struck.clear()
    this.render()
  }

  render() {
    const done = PRIMES.every((prime) => this.struck.has(prime))

    this.keyTargets.forEach((key, i) => key.setAttribute("aria-pressed", this.struck.has(PRIMES[i])))
    this.cellTargets.forEach((cell) => {
      const n = Number(cell.dataset.number)
      const gone = n === 1 || [...this.struck].some((prime) => n !== prime && n % prime === 0)
      const kept = done && !gone
      cell.classList.toggle("line-through", gone && n !== 1)
      cell.classList.toggle("text-gray-400", gone)
      cell.classList.toggle("bg-gray-100", gone)
      cell.classList.toggle("bg-green-100", kept)
      cell.classList.toggle("text-green-800", kept)
    })
    this.noteTarget.textContent = done ? this.copyValue.note_done : this.copyValue.note_start
  }
}
