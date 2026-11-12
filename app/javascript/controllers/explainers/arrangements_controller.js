import { Controller } from "@hotwired/stimulus"

// „Броене на възможности": every order in which 2, 3 or 4 different flags
// can hang, listed in dictionary order so the ones that start with the same
// flag sit together — n blocks of (n − 1)! — and the product n · (n − 1) · …
// · 1 can be read off the list itself. Each flag is a square with its own
// letter as well as its own shade, so the rows can be told apart without
// seeing colour. Four flags is the limit: 24 rows still fit a phone, 120
// would not.
const FLAGS = [
  "bg-primary-600 text-white",
  "bg-primary-200 text-primary-900",
  "bg-primary-900 text-white",
  "bg-white text-primary-900 ring-2 ring-inset ring-primary-600"
]

// Every order of `items`, in dictionary order.
const orders = (items) => items.length <= 1
  ? [items]
  : items.flatMap((first, i) => orders([...items.slice(0, i), ...items.slice(i + 1)]).map((rest) => [first, ...rest]))

export default class extends Controller {
  static targets = ["count", "figure", "total", "work", "note"]
  static values = { copy: Object }

  connect() {
    // The article's own example: three flags, 3 · 2 · 1 = 6.
    this.n = 3
    this.render()
  }

  pick({ params: { n } }) {
    this.n = n
    this.render()
  }

  render() {
    const copy = this.copyValue
    const n = this.n
    const all = orders(Array.from({ length: n }, (_, i) => i))
    const factors = Array.from({ length: n }, (_, i) => n - i)
    const list = all.map((order) => order.map((flag) => copy.letters[flag]).join("")).join(", ")
    const fill = (text) => text.replaceAll("%{n}", n).replaceAll("%{count}", all.length).replaceAll("%{list}", list)

    this.countTargets.forEach((button, index) => button.setAttribute("aria-pressed", index + 2 === n))
    this.figureTarget.setAttribute("aria-label", fill(copy.figure))
    // One strip per first flag, with a rule between strips, so the n equal
    // blocks stay apart however the rows wrap.
    this.figureTarget.replaceChildren(...factors.map((_, first) => {
      const group = document.createElement("div")
      group.className = `flex flex-wrap justify-center gap-2${first > 0 ? " border-t-2 border-ink-200 pt-3" : ""}`
      group.append(...all.filter((order) => order[0] === first).map((order) => this.row(order)))
      return group
    }))
    this.totalTarget.textContent = fill(copy.total)
    this.workTarget.textContent = `${factors.join(" · ")} = ${all.length}`
    this.noteTarget.textContent = copy.reasons[n]
  }

  // One order as a strip of lettered squares.
  row(order) {
    const row = document.createElement("span")
    row.className = "inline-flex gap-[3px] rounded-[8px] bg-white p-1 ring-1 ring-ink-200"
    for (const flag of order) {
      const square = document.createElement("span")
      square.className = `grid h-6 w-6 place-items-center rounded-[5px] text-meta font-black ${FLAGS[flag]}`
      square.textContent = this.copyValue.letters[flag]
      row.append(square)
    }
    return row
  }
}
