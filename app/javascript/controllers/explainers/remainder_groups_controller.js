import { Controller } from "@hotwired/stimulus"

// „Деление с остатък": n dots dealt into groups of d. A full group is a box
// of d filled dots; what is left over sits apart as outlined dots in a dashed
// box, so the remainder is told from the groups by shape and not by colour.
// Sliding n up by one shows the whole idea: the remainder climbs to d − 1 and
// then turns into a new box. Plain HTML that wraps, so twenty boxes of two
// fit a phone as well as four boxes of nine.
const DOT = "h-2.5 w-2.5 rounded-full"
const BOX = "inline-flex items-center gap-[3px] rounded-[10px] p-1.5"

export default class extends Controller {
  static targets = ["n", "d", "nOut", "dOut", "figure", "division", "equation", "note"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const n = Number(this.nTarget.value)
    const d = Number(this.dTarget.value)
    const q = Math.floor(n / d)
    const r = n - d * q
    const fill = (text) => text.replaceAll("%{n}", n).replaceAll("%{d}", d).replaceAll("%{q}", q).replaceAll("%{r}", r)

    this.nOutTarget.textContent = n
    this.dOutTarget.textContent = d

    const groups = this.part(fill(copy.groups))
    for (let i = 0; i < q; i++) groups.lastChild.append(this.box(d, `${BOX} bg-white ring-2 ring-primary-600`, `${DOT} bg-primary-600`))
    const rest = this.part(fill(copy.rest))
    if (r > 0) rest.lastChild.append(this.box(r, `${BOX} border-2 border-dashed border-ink-400`, `${DOT} bg-white ring-2 ring-primary-600`))

    this.figureTarget.setAttribute("aria-label", fill(copy.figure))
    this.figureTarget.replaceChildren(groups, rest)
    this.divisionTarget.textContent = fill(copy.division)
    this.equationTarget.textContent = fill(copy.equation)
    this.noteTarget.textContent = fill(q === 0 ? copy.note_none : r === 0 ? copy.note_exact : copy.note_rest)
  }

  // A captioned strip the boxes go into; it keeps its height when empty so
  // the page does not jump as the remainder comes and goes.
  part(caption) {
    const part = document.createElement("div")
    part.className = "flex flex-col gap-1.5"
    const title = document.createElement("p")
    title.className = "text-meta font-black text-ink-600"
    title.textContent = caption
    const strip = document.createElement("div")
    strip.className = "flex min-h-[26px] flex-wrap gap-2"
    part.append(title, strip)
    return part
  }

  box(count, boxClass, dotClass) {
    const box = document.createElement("span")
    box.className = boxClass
    for (let i = 0; i < count; i++) {
      const dot = document.createElement("span")
      dot.className = dotClass
      box.append(dot)
    }
    return box
  }
}
