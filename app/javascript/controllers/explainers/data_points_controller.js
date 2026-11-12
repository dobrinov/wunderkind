import { Controller } from "@hotwired/stimulus"

// „Средно, медиана и мода": school marks from 2 to 6 as dots stacked over a
// number line. A button under the line adds a mark, a tap on a column of
// dots takes one away (each column is one button, since any dot in it is the
// same mark), and the four numbers are worked out underneath with what they
// were worked out from: the sum and the count, the ordered list with its
// middle marked, the most frequent mark, the largest minus the smallest.
// It starts on 5, 6, 5, 6, 5 because one added 2 then drops the mean from
// 5,4 to about 4,83 while the median stays 5. Five marks wide, so every
// column is a full-size tap target on a phone; plain HTML, no drawing.
const START = [5, 6, 5, 6, 5]
const MOST = 12

// Mean, median, mode and range of a non-empty list of whole numbers. The
// mode follows one convention: every value that occurs most often is a mode,
// unless all the distinct values (more than one) occur equally often — then
// there is none.
export function describe(values) {
  const sorted = [...values].sort((one, other) => one - other)
  const count = sorted.length
  const sum = sorted.reduce((total, value) => total + value, 0)
  const middle = count % 2 === 1 ? [(count - 1) / 2] : [count / 2 - 1, count / 2]
  const median = middle.reduce((total, index) => total + sorted[index], 0) / middle.length

  const times = new Map()
  for (const value of sorted) times.set(value, (times.get(value) || 0) + 1)
  const most = Math.max(...times.values())
  const frequent = [...times.keys()].filter((value) => times.get(value) === most)
  const modes = times.size > 1 && frequent.length === times.size ? [] : frequent

  return { sorted, count, sum, mean: sum / count, middle, median, modes, min: sorted[0], max: sorted[count - 1] }
}

export default class extends Controller {
  static targets = ["figure", "column", "add", "mean", "sorted", "median", "mode", "range", "note", "full"]
  static values = { copy: Object }

  connect() {
    this.marks = [...START]
    this.render()
  }

  add({ currentTarget }) {
    if (this.marks.length >= MOST) return
    this.marks.push(Number(currentTarget.dataset.value))
    this.render()
    // At the limit every „add" button switches off: the keyboard goes to the
    // column of the mark just added, where one can be taken away again.
    if (currentTarget.disabled) this.partner(this.columnTargets, currentTarget).focus()
  }

  remove({ currentTarget }) {
    const index = this.marks.lastIndexOf(Number(currentTarget.dataset.value))
    if (index < 0 || this.marks.length <= 1) return
    this.marks.splice(index, 1)
    this.render()
    // An emptied column (or the last mark left) switches its button off: the
    // keyboard goes to the „add" button under it.
    if (currentTarget.disabled) this.partner(this.addTargets, currentTarget).focus()
  }

  // The button for the same mark in the other row.
  partner(buttons, button) {
    return buttons.find((other) => other.dataset.value === button.dataset.value)
  }

  render() {
    const copy = this.copyValue
    const data = describe(this.marks)
    const round = (value) => Math.round(value * 100) / 100
    const num = (value) => String(round(value)).replace(".", copy.point)
    const fill = (text, values) => Object.entries(values).reduce((out, [key, value]) => out.replaceAll(`%{${key}}`, value), text)

    // The dots: one per mark, stacked from the line up.
    this.columnTargets.forEach((column) => {
      const mark = Number(column.dataset.value)
      const dots = this.marks.filter((value) => value === mark).map(() => {
        const dot = document.createElement("span")
        dot.className = "h-3.5 w-3.5 shrink-0 rounded-full bg-primary-600"
        return dot
      })
      column.replaceChildren(...dots)
      column.disabled = dots.length === 0 || data.count <= 1
    })
    this.addTargets.forEach((button) => { button.disabled = data.count >= MOST })
    this.figureTarget.setAttribute("aria-label", fill(copy.figure, { values: data.sorted.join(", ") }))

    this.meanTarget.textContent = fill(copy.mean, {
      sum: data.sum, count: data.count, mean: num(data.mean),
      rel: Math.abs(data.mean - round(data.mean)) < 1e-9 ? "=" : "≈"
    })

    // The ordered list, the middle one or two picked out.
    this.sortedTarget.replaceChildren(...data.sorted.map((value, index) => {
      const chip = document.createElement("span")
      chip.className = data.middle.includes(index) ? "rounded-md bg-primary-600 px-2 text-white" : "px-1"
      chip.textContent = value
      return chip
    }))
    this.medianTarget.textContent = data.middle.length === 1
      ? fill(copy.median_odd, { median: num(data.median) })
      : fill(copy.median_even, { low: data.sorted[data.middle[0]], high: data.sorted[data.middle[1]], median: num(data.median) })

    this.modeTarget.textContent = data.modes.length === 0 ? copy.mode_none
      : fill(data.modes.length === 1 ? copy.mode_one : copy.mode_many, { modes: data.modes.join(", ") })
    this.rangeTarget.textContent = fill(copy.range, { max: data.max, min: data.min, range: data.max - data.min })

    const gap = data.mean - data.median
    this.noteTarget.textContent = data.count === 1 ? copy.note_single
      : Math.abs(gap) < 1e-9 ? copy.note_equal : gap > 0 ? copy.note_above : copy.note_below
    this.fullTarget.hidden = data.count < MOST
  }
}
