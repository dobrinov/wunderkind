import { Controller } from "@hotwired/stimulus"

// „Показателна функция": a square sheet, 32 cm a side and 0,1 mm thick, folded
// in half n times. The thickness is 0,1 mm · 2ⁿ — written in the unit that
// fits and set beside something of that height — and the last four folds are
// drawn as bars, each double the one before: growth by a factor, not by an
// amount. The second key reads the same folds as decay: the sheet's area,
// 1024 cm² · (½)ⁿ. The side is 32 cm so that the area is a power of two and
// reaches exactly 1 cm² at the tenth fold. The bars are HTML, not SVG, so
// their labels stay full-size text on a phone and can wrap.
const MAX = 30
const SUPERSCRIPTS = "⁰¹²³⁴⁵⁶⁷⁸⁹"
const BARS = 4, TALLEST = 140 // how many folds the chart shows, and its tallest bar in px

// What the stack is as tall as, from this many folds on. Every line is true
// for every n it covers: 0,1 mm · 2ⁿ is 1,28 cm at 7, 10,24 cm at 10, 1,64 m
// at 14, 3,28 m at 15, 52 m at 19, 419 m at 22, 839 m at 23, 3,36 km at 25,
// 13,4 km at 27 and 107 km at 30.
const HEIGHTS = [[0, "thick_thin"], [7, "thick_book"], [10, "thick_pile"], [14, "thick_person"], [15, "thick_room"], [19, "thick_block"],
  [22, "thick_eiffel"], [23, "thick_burj"], [25, "thick_musala"], [27, "thick_everest"], [30, "thick_space"]]
// The area: 1 cm² exactly at 10, under 1 mm² from 17 (0,78 mm²) on.
const AREAS = [[0, "area_whole"], [1, "area_half"], [10, "area_cm"], [11, "area_under_cm"], [17, "area_under_mm"]]

export default class extends Controller {
  static targets = ["mode", "n", "nOut", "fold", "reset", "value", "compare", "layers", "figure", "note"]
  static values = { copy: Object }

  connect() {
    this.half = false
    this.render()
  }

  switch(event) {
    this.half = event.currentTarget.dataset.mode === "half"
    this.render()
  }

  fold() {
    this.nTarget.value = Math.min(MAX, Number(this.nTarget.value) + 1)
    this.render()
    // The thirtieth fold disables the button under the reader's finger; hand
    // the keyboard's place to the one thing left to do.
    if (this.foldTarget.disabled) this.resetTarget.focus()
  }

  reset() {
    this.nTarget.value = 0
    this.render()
  }

  render() {
    const copy = this.copyValue
    const n = Number(this.nTarget.value)
    const now = this.quantity(n)
    const milestones = this.half ? AREAS : HEIGHTS
    const sup = String(n).split("").map((digit) => SUPERSCRIPTS[digit]).join("")

    this.modeTargets.forEach((key) => key.setAttribute("aria-pressed", String((key.dataset.mode === "half") === this.half)))
    this.nOutTarget.textContent = n
    this.foldTarget.disabled = n === MAX
    this.valueTarget.textContent = (this.half ? copy.area : copy.thick).replaceAll("%{sup}", sup).replaceAll("%{value}", `${now.exact ? "=" : "≈"}\u00a0${now.text}`)
    this.compareTarget.textContent = copy[milestones.filter(([from]) => n >= from).pop()[1]]
    this.layersTarget.textContent = copy.layers.replaceAll("%{layers}", this.grouped(2 ** n))
    this.noteTarget.textContent = this.half ? copy.note_half : copy.note_double
    this.figureTarget.replaceChildren(this.chart(n, (this.half ? copy.figure_half : copy.figure_double).replaceAll("%{n}", n).replaceAll("%{value}", this.shown(now))))
  }

  // The thickness (or the area) after n folds, in the unit that keeps the
  // number between 1 and 1000 where there is one: { size, text, exact }.
  // `size` is in mm or mm², for comparing bars.
  quantity(n) {
    const copy = this.copyValue
    let size, value, unit
    if (this.half) {
      size = 102400 / 2 ** n // 1024 cm² in mm²
      ;[value, unit] = size >= 100 ? [size / 100, copy.unit_cm2] : [size, copy.unit_mm2]
    } else {
      size = 0.1 * 2 ** n
      ;[value, unit] = size < 10 ? [size, copy.unit_mm] : size < 1000 ? [size / 10, copy.unit_cm] : size < 1e6 ? [size / 1000, copy.unit_m] : [size / 1e6, copy.unit_km]
    }
    // Four significant digits when that is the whole number (10,24 cm), else
    // three — and two for the very small ones, to keep them short.
    const same = (rounded) => Math.abs(rounded - value) <= value * 1e-9
    const four = Number(value.toPrecision(4))
    const rounded = same(four) ? four : Number(value.toPrecision(value < 0.01 ? 2 : 3))
    return { size, text: `${String(rounded).replace(".", copy.point)}\u00a0${unit}`, exact: same(rounded) }
  }

  // A value on its own: "1,28 cm" when exact, "≈ 1,64 m" when rounded.
  shown(quantity) {
    return (quantity.exact ? "" : "≈\u00a0") + quantity.text
  }

  // 1 073 741 824 — digits in threes, from 10 000 up.
  grouped(whole) {
    const digits = String(whole)
    return whole < 10000 ? digits : digits.replace(/\B(?=(\d{3})+$)/g, this.copyValue.group)
  }

  // A bar for each of the last four folds, as tall as its share of the tallest
  // one: 1, ½, ¼, ⅛ — whichever way the mode runs.
  chart(n, label) {
    const copy = this.copyValue
    const chart = this.element("div", "flex h-[212px] w-full max-w-[460px] items-end justify-center gap-2 border-b-2 border-ink-300")
    chart.setAttribute("role", "img")
    chart.setAttribute("aria-label", label)

    const folds = []
    for (let fold = Math.max(0, n - BARS + 1); fold <= n; fold++) folds.push(fold)
    const tallest = Math.max(...folds.map((fold) => this.quantity(fold).size))

    for (const fold of folds) {
      const quantity = this.quantity(fold)
      const column = this.element("div", "flex min-w-0 max-w-24 flex-1 flex-col items-center justify-end gap-1")
      const bar = this.element("div", `w-full max-w-14 rounded-t-[6px] ${fold === n ? "bg-primary-600" : "bg-primary-200"}`)
      bar.style.height = `${Math.max(2, Math.round((TALLEST * quantity.size) / tallest))}px`
      column.append(
        this.element("span", "text-center text-[11px] font-black leading-tight tabular-nums text-primary-900 sm:text-[13px]", this.shown(quantity)),
        bar,
        this.element("span", "pb-1 text-[12px] font-extrabold leading-none text-ink-600", copy.bar_label.replaceAll("%{n}", fold))
      )
      chart.append(column)
    }
    return chart
  }

  element(tag, classes, content) {
    const element = document.createElement(tag)
    element.className = classes
    if (content !== undefined) element.textContent = content
    return element
  }
}
