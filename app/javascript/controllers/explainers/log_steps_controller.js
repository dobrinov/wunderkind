import { Controller } from "@hotwired/stimulus"

// „Какво е логаритъм": from 1 to b by multiplying by a, one hop per
// multiplication — 1 → 2 → 4 → 8 … — so that logₐ b is something counted:
// the number of hops. The second row cuts the very same hops in two, the
// ones up to x and the ones from x on to b = x · y, which is the product
// rule with nothing left to prove: the numbers multiply, the hops add.
// The hops are chips that wrap rather than a drawn number line, because
// 10⁸ has nine digits and a phone is 390 px wide.
const SUPERSCRIPTS = "⁰¹²³⁴⁵⁶⁷⁸⁹"
const SUBSCRIPTS = "₀₁₂₃₄₅₆₇₈₉"
const CHIP = "grid min-h-10 place-items-center rounded-[10px] px-2.5 text-ui font-black tabular-nums"
const digits = (number, alphabet) => String(number).split("").map((digit) => alphabet[digit]).join("")

export default class extends Controller {
  static targets = ["base", "c", "cOut", "chain", "result", "m", "mOut", "split", "product", "note"]
  static values = { copy: Object }

  connect() {
    this.a = 2
    this.wanted = Number(this.mTarget.value) // where the reader put x, kept while b is too small for it
    this.render()
  }

  cut() {
    this.wanted = Number(this.mTarget.value)
    this.render()
  }

  pick(event) {
    this.a = Number(event.currentTarget.dataset.base)
    this.render()
  }

  render() {
    const copy = this.copyValue
    const a = this.a
    const c = Number(this.cTarget.value)           // b = aᶜ
    // x = aᵐ takes the first m of the c hops; it cannot take more than there
    // are, but goes back to where the reader put it once b is large enough again.
    this.mTarget.max = c
    const m = Math.min(this.wanted, c)
    this.mTarget.value = m
    const k = c - m                                // y = aᵏ takes the rest
    const b = a ** c, x = a ** m, y = a ** k
    const fill = (text) => text.replaceAll("%{sub}", digits(a, SUBSCRIPTS)).replaceAll("%{sup}", digits(c, SUPERSCRIPTS))
      .replaceAll("%{a}", a).replaceAll("%{b}", this.grouped(b)).replaceAll("%{c}", c)
      .replaceAll("%{x}", this.grouped(x)).replaceAll("%{y}", this.grouped(y)).replaceAll("%{m}", m).replaceAll("%{k}", k)
      .replaceAll("%{first}", this.hops(m)).replaceAll("%{second}", this.hops(k)).replaceAll("%{hops}", this.hops(c))

    this.baseTargets.forEach((key) => key.setAttribute("aria-pressed", String(Number(key.dataset.base) === a)))
    this.cOutTarget.textContent = this.grouped(b)
    this.mOutTarget.textContent = this.grouped(x)

    this.chainTarget.replaceChildren(...this.row(0, c, c))
    this.chainTarget.setAttribute("aria-label", fill(copy.figure))
    this.resultTarget.textContent = fill(copy.result)

    this.splitTarget.replaceChildren(this.part(0, m, x, m, true, "bg-primary-50"), this.part(m, c, y, k, false, "bg-ink-100"))
    this.splitTarget.setAttribute("aria-label", fill(copy.split_figure))
    this.productTarget.textContent = fill(copy.product)
    this.noteTarget.textContent = fill(copy.product_note)
  }

  // "1 скок", "3 скока", "0 скока".
  hops(count) {
    return (count === 1 ? this.copyValue.hops_one : this.copyValue.hops_many).replaceAll("%{count}", count)
  }

  // 100 000 000 — digits in threes, from 10 000 up.
  grouped(whole) {
    const text = String(whole)
    return whole < 10000 ? text : text.replace(/\B(?=(\d{3})+$)/g, this.copyValue.group)
  }

  // The chips for a^from … a^to with a "× a" hop before each one after a^from.
  // A hop and the chip it leads to are one unit, so a line never ends on an
  // arrow pointing at nothing. `start` says whether a^from itself is shown
  // (the second part of a split begins with a hop, since its starting chip
  // closes the first part); the chip for a^last is the one filled in.
  row(from, to, last, start = true) {
    const chip = (power) => this.element("span", `${CHIP} ${power === last ? "bg-primary-600 text-white" : "bg-white text-ink-900 ring-1 ring-ink-200"}`, this.grouped(this.a ** power))
    const elements = start ? [chip(from)] : []
    for (let power = from + 1; power <= to; power++) {
      const hop = this.element("span", "flex flex-col items-center px-0.5 text-[12px] font-black leading-none text-primary-700")
      hop.append(this.element("span", "", this.copyValue.times.replaceAll("%{a}", this.a)), this.element("span", "text-base leading-none", "→"))
      const unit = this.element("span", "inline-flex items-center gap-1.5")
      unit.append(hop, chip(power))
      elements.push(unit)
    }
    return elements
  }

  // One part of the split: its caption — "3 скока: log₂ 8 = 3" — over its hops.
  // Only the first part shows its starting chip, the 1.
  part(from, to, value, count, start, tone) {
    const copy = this.copyValue
    const box = this.element("div", `flex flex-col gap-1.5 rounded-[12px] p-2 ${tone}`)
    const caption = copy.caption.replaceAll("%{hops}", this.hops(count)).replaceAll("%{sub}", digits(this.a, SUBSCRIPTS))
      .replaceAll("%{value}", this.grouped(value)).replaceAll("%{count}", count)
    box.append(this.element("p", "text-[13px] font-extrabold text-ink-800", caption))
    const hops = this.element("div", "flex flex-wrap items-center gap-x-1.5 gap-y-2")
    hops.append(...this.row(from, to, Number(this.cTarget.value), start))
    box.append(hops)
    return box
  }

  element(tag, classes, content) {
    const element = document.createElement(tag)
    if (classes) element.className = classes
    if (content !== undefined) element.textContent = content
    return element
  }
}
