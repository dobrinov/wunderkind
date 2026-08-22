import { Controller } from "@hotwired/stimulus"
import { MathfieldElement } from "mathlive"

MathfieldElement.fontsDirectory = "/mathlive-fonts"
MathfieldElement.soundsDirectory = null
// Bulgarian writes 1,5 — so the keyboard's separator key, and the field, use a
// comma. The grader reads both, but the child should see the notation they are
// taught.
MathfieldElement.decimalSeparator = ","

// The keypad a child answering a maths question needs, in place of MathLive's
// default layout — which opens on x, n, e, i, an integral sign and ∀∃. The ÷
// key builds a stacked fraction, which is how ½ gets typed on a phone with no
// physical keyboard; everything here is one of MathLive's own keys, so the
// labels and the shift variants stay theirs.
const ANSWER_KEYPAD = {
  label: "123",
  tooltip: "keyboard.tooltip.numeric",
  rows: [
    ["[7]", "[8]", "[9]", "[/]", "[separator-5]", { latex: "\\%" }, { latex: "\\pi" }],
    ["[4]", "[5]", "[6]", "[*]", "[separator-5]", { class: "hide-shift", latex: "#@^2}" }, { class: "hide-shift", latex: "\\sqrt{#0}" }],
    ["[1]", "[2]", "[3]", "[-]", "[separator-5]", "[(]", "[)]"],
    ["[0]", "[.]", "[+]", "[backspace]", "[separator-5]", "[left]", "[right]", "[hide-keyboard]"]
  ]
}

// A MathLive field for exact-value answers. The student types naturally
// (fractions, decimals, powers); the plain value lands in the hidden input.
export default class extends Controller {
  static targets = ["field", "hidden"]

  connect() {
    this.mathfield = new MathfieldElement()
    this.mathfield.smartFence = true
    this.mathfield.mathVirtualKeyboardPolicy = "auto"
    this.mathfield.style.width = "100%"
    this.fieldTarget.appendChild(this.mathfield)
    this.mathfield.addEventListener("input", () => this.sync())
    // The virtual keyboard is one shared object per page, so the layout is set
    // as the field takes focus rather than globally — the authoring popover's
    // own field keeps MathLive's full keyboard.
    this.mathfield.addEventListener("focusin", () => this.useKeypad())
    this.mathfield.focus()
  }

  disconnect() {
    this.mathfield?.remove()
  }

  useKeypad() {
    if (window.mathVirtualKeyboard) window.mathVirtualKeyboard.layouts = [ANSWER_KEYPAD]
  }

  sync() {
    // ASCII math is close enough to what the server parses (3/4, 0,75, 75%).
    this.hiddenTarget.value = normalize(this.mathfield.getValue("ascii-math"))
  }
}

// MathLive serializes a fraction with both parts parenthesized — ½ comes out as
// "(1)/(2)" and 1½ as "1(1)/(2)". The grader unwraps that too, but this value is
// also read back to the child in the feedback card, so it should say what they
// wrote. The mixed number goes first: without the space it would become 11/2.
function normalize(value) {
  return value
    .replace(/(\d)\s*\((\d+)\)\s*\/\s*\((\d+)\)/g, "$1 $2/$3")
    .replace(/\((-?\d+)\)\s*\/\s*\((\d+)\)/g, "$1/$2")
    .trim()
}
