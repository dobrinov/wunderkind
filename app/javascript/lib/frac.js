// Maths in a question body is KaTeX-rendered, so a widget that asks a child to
// order "3/4" alongside a typeset ¾ is speaking two notations at once. The
// widgets build their labels in the DOM, so they need this rather than the
// server-side shared/_frac partial — same markup, same .frac rules.
//
// Deliberately narrow, and matching the FRACTION regex in ApplicationHelper: a
// whole string that is nothing but one fraction. "0,75" and "1 1/2" are left as
// typed rather than half-rendered.
const FRACTION = /^\s*(-?\d+)\s*\/\s*(\d+)\s*$/

// Returns a <span class="frac"> for a bare fraction, or a plain text node.
export function mathNode(text) {
  const match = FRACTION.exec(String(text))
  if (!match) return document.createTextNode(String(text))

  const frac = document.createElement("span")
  frac.className = "frac"
  for (const part of [match[1], match[2]]) {
    const span = document.createElement("span")
    span.textContent = part
    frac.appendChild(span)
  }
  return frac
}

// Replaces an element's contents with the rendered value.
export function setMath(element, text) {
  element.replaceChildren(mathNode(text))
}
