import { Controller } from "@hotwired/stimulus"

// Balance scale widget: an equation as two pans of x boxes and unit weights.
// Every move is done to both pans — take k units off, take k x off, divide by
// k — and a move a pan cannot take is refused, exactly as Widgets.balance_after
// replays it. The moves are the working; the value typed for x is the answer.
// State: {steps: [{op, k}], x: "3"}, submitted once x has a value.
export default class extends Controller {
  static targets = ["scale", "chain", "refusal", "k", "undo", "answer", "hidden"]
  static values = { left: Object, right: Object }

  connect() {
    this.steps = []
    this.ks = { units: 1, x: 1, divide: 2 }
    this.render()
  }

  increment({ params: { op } }) {
    this.setK(op, this.ks[op] + 1)
  }

  decrement({ params: { op } }) {
    this.setK(op, this.ks[op] - 1)
  }

  setK(op, k) {
    const min = op === "divide" ? 2 : 1
    this.ks[op] = Math.min(Math.max(k, min), 60)
    this.kTargets.find((element) => element.dataset.op === op).textContent = this.ks[op]
  }

  apply({ params: { op } }) {
    const step = { op, k: this.ks[op] }
    if (!this.after([...this.steps, step])) {
      this.refusalTarget.hidden = false
      return
    }
    this.steps.push(step)
    this.render()
  }

  undo() {
    this.steps.pop()
    this.render()
  }

  sync() {
    const x = this.answerTarget.value.trim()
    this.hiddenTarget.value = x ? JSON.stringify({ steps: this.steps, x }) : ""
  }

  // The pans after these moves, or null when one of them is not allowed.
  after(steps) {
    let sides = [this.leftValue, this.rightValue].map((side) => ({ x: Number(side.x) || 0, units: Number(side.units) || 0 }))
    for (const { op, k } of steps) {
      if (!(k > 0)) return null
      if (op === "units" || op === "x") {
        if (!sides.every((side) => side[op] >= k)) return null
        sides = sides.map((side) => ({ ...side, [op]: side[op] - k }))
      } else if (op === "divide") {
        if (!sides.every((side) => side.x % k === 0 && side.units % k === 0)) return null
        sides = sides.map((side) => ({ x: side.x / k, units: side.units / k }))
      } else {
        return null
      }
    }
    return sides
  }

  // The same words as Widgets.balance_equation: "3x + 2", "x", "11".
  equation(side) {
    const terms = []
    if (side.x > 0) terms.push(side.x === 1 ? "x" : `${side.x}x`)
    if (side.units > 0 || terms.length === 0) terms.push(String(side.units))
    return terms.join(" + ")
  }

  render() {
    const [left, right] = this.after(this.steps)
    this.refusalTarget.hidden = true
    this.undoTarget.disabled = this.steps.length === 0

    const chain = [[this.leftValue, this.rightValue], ...this.steps.map((_, i) => this.after(this.steps.slice(0, i + 1)))]
      .map((sides) => sides.map((side) => this.equation({ x: Number(side.x) || 0, units: Number(side.units) || 0 })).join(" = "))
    this.chainTarget.textContent = chain.join(" → ")

    const current = `${this.equation(left)} = ${this.equation(right)}`
    this.scaleTarget.setAttribute("aria-label", current)
    this.scaleTarget.replaceChildren(this.drawScale(left, right))
    this.sync()
  }

  drawScale(left, right) {
    const scale = document.createElement("div")
    scale.className = "relative mx-auto w-full max-w-md select-none"

    const pans = document.createElement("div")
    pans.className = "relative z-10 grid grid-cols-2 gap-6"
    pans.append(this.drawPan(left), this.drawPan(right))

    const beam = document.createElement("div")
    beam.className = "mx-3 h-2 rounded-full bg-ink-700"

    const stand = document.createElement("div")
    stand.className = "mx-auto h-10 w-2 rounded-b-full bg-ink-700"

    const base = document.createElement("div")
    base.className = "mx-auto h-3 w-24 rounded-full bg-ink-700"

    scale.append(pans, beam, stand, base)
    return scale
  }

  drawPan(side) {
    const pan = document.createElement("div")
    pan.className = "flex flex-col"

    const load = document.createElement("div")
    load.className = "flex min-h-24 flex-wrap content-end items-end justify-center gap-1.5 px-1 pb-1.5"

    for (let i = 0; i < side.x; i++) {
      const box = document.createElement("span")
      box.className = "grid size-10 place-items-center rounded-[10px] bg-primary-600 text-lg font-black italic text-white shadow-[0_3px_0_var(--color-primary-800)]"
      box.textContent = "x"
      load.append(box)
    }

    // Tens as bars of ten, so sixty weights still read at a glance.
    for (let i = 0; i < Math.floor(side.units / 10); i++) {
      const bar = document.createElement("span")
      bar.className = "h-3.5 w-16 rounded-[3px] bg-amber-400 shadow-[0_2px_0_var(--color-amber-700)]"
      bar.style.backgroundImage = "repeating-linear-gradient(90deg, transparent 0 calc(10% - 1px), rgb(180 83 9 / .45) calc(10% - 1px) 10%)"
      load.append(bar)
    }
    for (let i = 0; i < side.units % 10; i++) {
      const unit = document.createElement("span")
      unit.className = "size-3.5 rounded-[3px] bg-amber-400 shadow-[0_2px_0_var(--color-amber-700)]"
      load.append(unit)
    }

    const dish = document.createElement("div")
    dish.className = "mb-1 h-2.5 rounded-b-[40px] bg-ink-400"

    pan.append(load, dish)
    return pan
  }
}
