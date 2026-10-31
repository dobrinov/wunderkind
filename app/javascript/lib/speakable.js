// Maths written for the eye, turned into what a Bulgarian voice should say.
// A text-to-speech voice reads „3/4" as „три наклонена черта четири" and „·"
// as nothing at all, so a seven-year-old hearing a problem read out would hear
// a different problem. Shared by the read-aloud button and its spec.
const RULES = [
  [/([\d)])\s*\/\s*(?=[\d(])/g, "$1 върху "],
  [/\s*[·×]\s*/g, " по "],
  [/(\d)\s*[:÷]\s*(\d)/g, "$1 делено на $2"],
  [/\s*\+\s*/g, " плюс "],
  [/([\da-zA-Z²³)])\s*[−–-]\s*(?=[\da-zA-Z(])/g, "$1 минус "],
  [/(^|[\s(])[−–-](?=\d)/g, "$1минус "],
  [/\s*≠\s*/g, " различно от "],
  [/\s*≤\s*/g, " по-малко или равно на "],
  [/\s*≥\s*/g, " по-голямо или равно на "],
  [/\s*<\s*/g, " по-малко от "],
  [/\s*>\s*/g, " по-голямо от "],
  [/\s*=\s*/g, " равно на "],
  [/(\d)\s*%/g, "$1 процента"],
  [/(\d)\s*°/g, "$1 градуса"],
  [/²/g, " на квадрат"],
  [/³/g, " на куб"],
  [/√\s*/g, "корен от "],
  [/π/g, " пи "],
  [/\s+/g, " "]
]

export function speakable(text) {
  return RULES.reduce((out, [pattern, replacement]) => out.replace(pattern, replacement), String(text)).trim()
}

// A formula KaTeX drew, back to the plain symbols speakable() reads. The page
// holds the source in data-math-latex-value; what KaTeX leaves in the DOM
// reads as the formula twice (its MathML and its HTML), run together.
export function latexToText(latex) {
  return String(latex)
    .replace(/\\[dt]?frac\{([^{}]*)\}\{([^{}]*)\}/g, "($1)/($2)")
    .replace(/\\sqrt\{([^{}]*)\}/g, "√($1)")
    .replace(/\^\{?2\}?/g, "²")
    .replace(/\^\{?3\}?/g, "³")
    .replace(/\^\{([^{}]*)\}/g, " на степен $1")
    .replace(/\^(\w)/g, " на степен $1")
    .replace(/\\cdot|\\times/g, "·")
    .replace(/\\div/g, ":")
    .replace(/\\pi/g, "π")
    .replace(/\\leq?/g, "≤")
    .replace(/\\geq?/g, "≥")
    .replace(/\\neq?/g, "≠")
    .replace(/\\circ/g, "°")
    .replace(/\\%/g, "%")
    .replace(/\\[a-zA-Z]+/g, " ")
    .replace(/[{}]/g, "")
    .replace(/\(([\w.,]+)\)/g, "$1")
}

// The words of a piece of the page as a reader would say them: a stacked
// fraction by its aria-label („3/4"), a KaTeX formula by its source.
export function textOf(element) {
  const copy = element.cloneNode(true)
  copy.querySelectorAll("[role=math][aria-label]").forEach((node) => node.replaceWith(` ${node.getAttribute("aria-label")} `))
  copy.querySelectorAll("[data-math-latex-value]").forEach((node) => node.replaceWith(` ${latexToText(node.getAttribute("data-math-latex-value"))} `))
  copy.querySelectorAll("[aria-hidden=true], .sr-only").forEach((node) => node.remove())
  return copy.textContent
}
