import { Controller } from "@hotwired/stimulus"
import { parseAuthoring, renderDoc, digitBefore } from "../lib/authoring"

// The problem editor: a native <textarea>, a row of symbol keys above it and
// a preview under it drawn by the same rules the server stores the problem by.
//
// It replaced a Tiptap editor with a MathLive popover, and the reasons are the
// design: a textarea is what an iPad already knows how to type, select, undo
// and dictate into; a fraction is "3/4" typed the way a child would write it
// on one line anyway, rather than five taps and two keyboards; and nothing
// the child types is ever hidden inside a node they have to click to see.
export default class extends Controller {
  static targets = ["input", "preview"]
  static values = { latex: Boolean }

  connect() {
    this.render()
  }

  render() {
    const doc = parseAuthoring(this.inputTarget.value, { latex: this.latexValue })
    this.previewTarget.replaceChildren(renderDoc(doc))
  }

  // The keys sit outside the textarea, and pressing one would take the focus
  // (and on an iPad, the keyboard) away from it. With a mouse, refusing the
  // pointerdown keeps both where they are. Not with a finger: Safari treats a
  // refused touch pointerdown as a cancelled tap and never sends the click, so
  // every key was dead on an iPad. A touch is refused at its end instead —
  // which also stops the focus moving — and the key's click is sent from here.
  keepFocus(event) {
    if (event.pointerType !== "touch") event.preventDefault()
  }

  tap(event) {
    event.preventDefault()
    event.currentTarget.click()
  }

  insert(event) {
    this.put(event.params.symbol)
  }

  // The fraction key, in three cases:
  //   - "3|"  → "3/|"   a numerator has just been typed, so this is its bar;
  //   - "|"   → "|/"    nothing yet, so the bar goes in and the caret waits in
  //                     front of it for the numerator;
  //   - "3|/" → "3/|"   pressed again over that bar, it steps past it to the
  //                     denominator rather than writing a second one.
  // So [÷] 3 [÷] 4 and 3 [÷] 4 both spell 3/4, and the preview stacks it the
  // moment the 4 is in.
  fraction() {
    const input = this.inputTarget
    const { selectionStart: start, selectionEnd: end, value } = this.caret()

    if (start === end && value[start] === "/") {
      this.focusAt(start + 1)
    } else if (digitBefore(value, start) || start !== end) {
      this.put("/")
    } else {
      this.put("/")
      this.focusAt(input.selectionStart - 1)
    }
  }

  // The admin form's `$…$`: around the selection if there is one, otherwise
  // an empty pair with the caret between the dollars.
  formula() {
    const { selectionStart: start, selectionEnd: end, value } = this.caret()
    this.put(`$${value.slice(start, end)}$`)
    if (start === end) this.focusAt(start + 1)
  }

  // A "/" typed on the keyboard over the bar the fraction key left waiting is
  // the same step past it, not a "//".
  beforeinput(event) {
    if (event.inputType !== "insertText" || event.data !== "/") return

    const { selectionStart: start, selectionEnd: end, value } = this.inputTarget
    if (start === end && value[start] === "/" && digitBefore(value, start)) {
      event.preventDefault()
      this.focusAt(start + 1)
    }
  }

  put(text) {
    const input = this.inputTarget
    const { selectionStart: start, selectionEnd: end } = this.caret()
    input.focus()
    input.setSelectionRange(start, end)

    // execCommand keeps the insertion in the textarea's own undo history (and
    // fires `input`); setRangeText is the fallback where it is gone.
    if (!document.execCommand?.("insertText", false, text)) {
      input.setRangeText(text, start, end, "end")
      input.dispatchEvent(new Event("input", { bubbles: true }))
    }
  }

  focusAt(index) {
    this.inputTarget.focus()
    this.inputTarget.setSelectionRange(index, index)
  }

  // A textarea that has never been focused reports its caret at 0 in some
  // browsers and at the end in others; a key pressed before anyone clicked
  // into it should add to the end, which is where the writing is.
  caret() {
    const input = this.inputTarget
    if (document.activeElement !== input && !this.touched) {
      const end = input.value.length
      return { selectionStart: end, selectionEnd: end, value: input.value }
    }
    return { selectionStart: input.selectionStart, selectionEnd: input.selectionEnd, value: input.value }
  }

  touch() {
    this.touched = true
  }
}
