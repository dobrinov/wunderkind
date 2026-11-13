import { Controller } from "@hotwired/stimulus"
import shapes from "../lib/calculators"

// A calculator page (calculators/show): tabs for the ways to work a figure
// out, sliders for its numbers, and under them the figure drawn to those
// numbers and the sum written out. The page arrives with every mode's formula
// and a worked example as text; this replaces the example with the working
// for whatever the sliders say. The arithmetic and the drawing are the page's
// module in lib/calculators, by `slug`.
export default class extends Controller {
  static targets = ["tab", "panel", "input", "readout", "figure", "steps", "result"]
  static values = { slug: String, copy: Object, decimal: { type: String, default: "," } }

  connect() {
    this.shape = shapes[this.slugValue]
    if (!this.shape) return

    this.mode = this.tabTargets.find((tab) => tab.classList.contains("is-active"))?.dataset.mode || this.tabTargets[0].dataset.mode
    this.render()
  }

  choose({ currentTarget }) {
    this.show(currentTarget.dataset.mode)
  }

  // Left and right move between the tabs, as a tablist's keys do.
  keys(event) {
    const step = { ArrowRight: 1, ArrowLeft: -1 }[event.key]
    if (!step) return

    event.preventDefault()
    const tabs = this.tabTargets
    const next = tabs[(tabs.indexOf(event.currentTarget) + step + tabs.length) % tabs.length]
    this.show(next.dataset.mode)
    next.focus()
  }

  show(mode) {
    this.mode = mode
    for (const tab of this.tabTargets) {
      const on = tab.dataset.mode === this.mode
      tab.classList.toggle("is-active", on)
      tab.setAttribute("aria-selected", on)
      tab.tabIndex = on ? 0 : -1
    }
    for (const panel of this.panelTargets) panel.hidden = panel.dataset.mode !== this.mode
    this.render()
  }

  update() {
    this.render()
  }

  render() {
    if (!this.shape) return

    const inputs = this.inputTargets.filter((input) => input.dataset.mode === this.mode)
    const values = Object.fromEntries(inputs.map((input) => [input.dataset.key, Number(input.value)]))
    const fmt = (value, digits = 2) => String(Math.round(value * 10 ** digits) / 10 ** digits).replace(".", this.decimalValue)
    const result = this.shape[this.mode](values, { fmt, copy: this.copyValue })

    for (const readout of this.readoutTargets) {
      if (readout.dataset.mode !== this.mode) continue
      const key = readout.dataset.key
      readout.textContent = result.readouts?.[key] ?? `${fmt(values[key])} ${this.copyValue.unit}`
    }

    const panel = this.panelTargets.find((candidate) => candidate.dataset.mode === this.mode)
    const steps = this.stepsTargets.find((target) => panel.contains(target))
    steps.textContent = result.steps.join("\n")
    this.resultTargets.find((target) => panel.contains(target)).classList.toggle("is-invalid", Boolean(result.invalid))

    this.figureTarget.innerHTML = result.svg
    this.figureTarget.setAttribute("aria-label", `${this.copyValue.figure}. ${result.steps.join(" ")}`)
  }
}
