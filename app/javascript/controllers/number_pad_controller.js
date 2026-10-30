import { Controller } from "@hotwired/stimulus"

// The answer field for a numeric question, with its own keypad — in place of
// MathLive, which put an English menu, a shift layer of ∞ Σ ± and "■⁷" keys and
// most of the page's JavaScript in front of a child typing "12". Every accepted
// answer in the bank is an integer, a decimal or a fraction, so that is all
// this types: digits, a decimal comma, a sign and one fraction bar.
//
// The field is drawn rather than typed into. A real <input> would bring up the
// system keyboard on a tablet (the letters one, or a decimal pad with no minus
// and no bar), and could not set "3/4" stacked while it is being typed. So the
// value is a plain string — exactly what lands in the hidden field and what
// ExactValue reads — and the field draws it, with a caret, a stacked fraction
// and an empty box where the next number goes. A physical keyboard types into
// it too, and anything that is not part of a number is simply not typed, so
// "8 евро" or "x=72" cannot be marked wrong for its wording.
const SIGN = "-"
const BAR = "/"
const NUMBER = /[0-9,]/

export default class extends Controller {
  static targets = ["display", "hidden", "message"]

  connect() {
    this.value = this.hiddenTarget.value || ""
    this.caret = this.value.length
    this.render()

    // The form's own submit handler (answer_form) posts whatever is in the
    // hidden field; an empty answer is stopped before it, here, with a word on
    // the field rather than a round trip that comes back „did not reach us".
    this.form = this.element.closest("form")
    this.guard = (event) => this.refuseEmpty(event)
    this.form?.addEventListener("submit", this.guard, { capture: true })

    if (this.displayTarget.hasAttribute("data-autofocus")) this.displayTarget.focus({ preventScroll: true })
  }

  disconnect() {
    this.form?.removeEventListener("submit", this.guard, { capture: true })
  }

  // --- Keys ------------------------------------------------------------------

  // Pressing a key must not take the focus off the field, or the caret goes
  // with it. A mouse press is refused on pointerdown; a finger cannot be (Safari
  // treats a refused touch pointerdown as a cancelled tap and never clicks), so
  // a touch is refused at its end and the click is sent from here — the same
  // two-step as plain_editor_controller.
  keepFocus(event) {
    if (event.pointerType !== "touch") event.preventDefault()
  }

  tap(event) {
    event.preventDefault()
    event.currentTarget.click()
  }

  press(event) {
    this.displayTarget.focus({ preventScroll: true })
    // Stimulus reads a param that looks like a number as one: "7" arrives as 7.
    const key = String(event.params.key)
    if (key === "backspace") this.backspace()
    else if (key === "sign") this.toggleSign()
    else if (key === "fraction") this.fraction()
    else this.insert(key)
  }

  // --- A physical keyboard ----------------------------------------------------

  keydown(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return

    const key = event.key
    if (/^[0-9]$/.test(key)) this.insert(key)
    else if (key === "," || key === ".") this.insert(",")
    else if (key === "-" || key === "−") this.toggleSign()
    else if (key === "/" || key === ":" || key === "÷") this.fraction()
    else if (key === "Backspace") this.backspace()
    else if (key === "Delete") this.deleteForward()
    else if (key === "ArrowLeft") this.moveTo(this.caret - 1)
    else if (key === "ArrowRight") this.moveTo(this.caret + 1)
    else if (key === "Home" || key === "ArrowUp") this.moveTo(0)
    else if (key === "End" || key === "ArrowDown") this.moveTo(this.value.length)
    else return

    event.preventDefault()
  }

  paste(event) {
    event.preventDefault()
    const text = (event.clipboardData?.getData("text") || "").trim()
    for (const char of text) {
      if (/[0-9]/.test(char)) this.insert(char)
      else if (char === "," || char === ".") this.insert(",")
      else if (char === "-" || char === "−") this.toggleSign()
      else if (char === "/") this.fraction()
    }
  }

  // A tap on the drawn number puts the caret beside the digit it landed on —
  // before it on the digit's left half, after it on the right.
  place(event) {
    const target = event.target.closest("[data-index]")
    if (!target) {
      this.moveTo(this.value.length)
      return
    }
    const index = Number(target.dataset.index)
    if (target.dataset.slot) {
      this.moveTo(index)
      return
    }
    const rect = target.getBoundingClientRect()
    this.moveTo(event.clientX > rect.left + rect.width / 2 ? index + 1 : index)
  }

  // --- Editing ---------------------------------------------------------------

  insert(char) {
    // One decimal comma per number: the part of the value the caret is in.
    if (char === ",") {
      const [ start, end ] = this.numberAround(this.caret)
      if (this.value.slice(start, end).includes(",")) return
      // ",5" is a comma with nothing in front of it; a child means 0,5.
      if (start === this.caret) char = "0,"
    }
    if (this.caret === 0 && this.value.startsWith(SIGN)) this.caret = 1
    this.splice(this.caret, 0, char)
  }

  backspace() {
    if (this.caret === 0) return
    this.splice(this.caret - 1, 1, "")
  }

  deleteForward() {
    if (this.caret >= this.value.length) return
    this.caret += 1
    this.backspace()
  }

  // The answer is a number, never a sum, so the minus key is the number's
  // sign wherever the caret is: on, then off again, like a calculator's ±.
  toggleSign() {
    if (this.value.startsWith(SIGN)) {
      this.value = this.value.slice(1)
      this.caret = Math.max(0, this.caret - 1)
    } else {
      this.value = SIGN + this.value
      this.caret += 1
    }
    this.changed()
  }

  // The fraction key, as in the problem editor:
  //   "3|"   → "3/|"  a numerator has been typed, so this is its bar;
  //   "|"    → "|/"   nothing yet: the bar goes in and the caret waits above it;
  //   "3|/4" → "3/|4" pressed over the bar, it steps down to the denominator.
  // There is only ever one bar; pressing it again anywhere goes below it.
  fraction() {
    const bar = this.value.indexOf(BAR)
    if (bar !== -1) {
      this.moveTo(bar + 1)
      return
    }
    if (NUMBER.test(this.value[this.caret - 1] || "")) {
      this.splice(this.caret, 0, BAR)
    } else {
      this.splice(this.caret, 0, BAR)
      this.moveTo(this.caret - 1)
    }
  }

  splice(at, remove, text) {
    this.value = this.value.slice(0, at) + text + this.value.slice(at + remove)
    this.caret = at + text.length
    this.changed()
  }

  moveTo(index) {
    this.caret = Math.min(Math.max(index, 0), this.value.length)
    this.render()
  }

  // The run of digits and commas the caret is in or beside.
  numberAround(index) {
    let start = index
    let end = index
    while (start > 0 && NUMBER.test(this.value[start - 1])) start -= 1
    while (end < this.value.length && NUMBER.test(this.value[end])) end += 1
    return [ start, end ]
  }

  changed() {
    this.hiddenTarget.value = this.value
    this.messageTarget.hidden = true
    this.element.classList.remove("is-refused")
    this.render()
  }

  refuseEmpty(event) {
    if (/[0-9]/.test(this.value)) return
    event.preventDefault()
    event.stopImmediatePropagation()
    this.messageTarget.hidden = false
    this.element.classList.remove("is-refused")
    // Restarted on every press, so a second empty press shakes again.
    void this.element.offsetWidth
    this.element.classList.add("is-refused")
    this.displayTarget.focus({ preventScroll: true })
  }

  // --- Drawing ---------------------------------------------------------------

  // Plain characters, except the one fraction: its numerator (the digits just
  // before the bar) and denominator (just after) are set stacked, each with an
  // empty box while it has nothing in it. The caret is drawn in whichever part
  // its index falls in.
  render() {
    const display = this.displayTarget
    const value = this.value
    const caret = this.caret
    const parts = document.createDocumentFragment()
    const bar = value.indexOf(BAR)

    const caretNode = () => {
      const node = document.createElement("span")
      node.className = "number-pad-caret"
      return node
    }

    // `drawn` is an index whose caret the fraction has already drawn at the
    // end of its denominator, so the text after it does not draw a second.
    const chars = (container, from, to, drawn = -1) => {
      for (let index = from; index < to; index += 1) {
        if (index === caret && index !== drawn) container.appendChild(caretNode())
        const span = document.createElement("span")
        span.dataset.index = index
        span.textContent = value[index] === SIGN ? "−" : value[index]
        container.appendChild(span)
      }
    }

    const slotOrCaret = (container, from, to) => {
      if (from === to) {
        const slot = document.createElement("span")
        slot.className = "number-pad-slot"
        slot.dataset.index = from
        slot.dataset.slot = "true"
        container.appendChild(slot)
        if (caret === from) slot.appendChild(caretNode())
        return
      }
      chars(container, from, to)
      if (caret === to) container.appendChild(caretNode())
    }

    if (bar === -1) {
      chars(parts, 0, value.length)
      if (caret === value.length) parts.appendChild(caretNode())
    } else {
      let numeratorStart = bar
      while (numeratorStart > 0 && NUMBER.test(value[numeratorStart - 1])) numeratorStart -= 1
      let denominatorEnd = bar + 1
      while (denominatorEnd < value.length && NUMBER.test(value[denominatorEnd])) denominatorEnd += 1

      chars(parts, 0, numeratorStart)
      const frac = document.createElement("span")
      frac.className = "frac"
      const numerator = document.createElement("span")
      const denominator = document.createElement("span")
      slotOrCaret(numerator, numeratorStart, bar)
      slotOrCaret(denominator, bar + 1, denominatorEnd)
      frac.append(numerator, denominator)
      parts.appendChild(frac)
      chars(parts, denominatorEnd, value.length, denominatorEnd)
      if (caret === value.length && denominatorEnd < value.length) parts.appendChild(caretNode())
    }

    const visual = document.createElement("span")
    visual.className = "number-pad-value"
    visual.setAttribute("aria-hidden", "true")
    visual.appendChild(parts)

    // What a screen reader hears: the value as typed, "3/4" read as such.
    const spoken = document.createElement("span")
    spoken.className = "sr-only"
    spoken.textContent = value.replaceAll(SIGN, "−")

    display.replaceChildren(visual, spoken)
    display.classList.toggle("is-empty", value === "")
  }
}
