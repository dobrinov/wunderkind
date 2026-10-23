import { Controller } from "@hotwired/stimulus"

// „Обиколка и лице": 20 metres of fence around a rectangular yard. The width
// slider fixes the length (10 − width), the yard is drawn to scale, and the
// area of every width is a bar — so the reader finds for themselves that the
// same fence holds the most grass as a square.
const FENCE = 20
const BEST = 25 // the 5 × 5 square
const BAR_HEIGHT = 140 // pixels for the tallest bar
const YARD_SCALE = 18 // pixels per metre in the yard drawing

export default class extends Controller {
  static targets = ["width", "widthOut", "yard", "bars", "note"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  size() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const width = Number(this.widthTarget.value)
    const length = FENCE / 2 - width
    const area = width * length
    const fill = (text, values) => Object.entries(values).reduce((out, [key, value]) => out.replaceAll(`%{${key}}`, value), text)

    this.widthOutTarget.textContent = fill(copy.metres, { n: width })
    this.yardTarget.style.width = `${width * YARD_SCALE}px`
    this.yardTarget.style.height = `${length * YARD_SCALE}px`
    this.yardTarget.setAttribute("aria-label", fill(copy.yard, { w: width, l: length }))

    this.barsTarget.replaceChildren(...Array.from({ length: 9 }, (_, i) => {
      const w = i + 1
      const s = w * (FENCE / 2 - w)
      const item = document.createElement("li")
      item.className = "flex flex-col items-center gap-1"
      item.setAttribute("aria-label", fill(copy.bar, { w, s }))

      const value = document.createElement("span")
      value.className = "text-xs font-black text-gray-700"
      value.textContent = s
      const bar = document.createElement("span")
      bar.className = [
        "block w-6 rounded-t-[5px]",
        w === width ? "bg-primary-600" : s === BEST ? "bg-green-400" : "bg-primary-200"
      ].join(" ")
      bar.style.height = `${(s / BEST) * BAR_HEIGHT}px`
      const label = document.createElement("span")
      label.className = "text-xs font-black text-gray-500"
      label.textContent = w

      item.append(value, bar, label)
      return item
    }))

    const note = fill(copy.note, { w: width, l: length, s: area })
    this.noteTarget.textContent = `${note} ${area === BEST ? copy.note_best : copy.note_try}`
  }
}
