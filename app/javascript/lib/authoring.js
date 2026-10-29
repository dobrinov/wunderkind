// The authoring language, for the editor's live preview: RichContent.parse_authoring
// in JavaScript. A line is a paragraph, a bare "3/4" is a fraction, and — only
// where the page asks for it (the admin form) — `$…$` is LaTeX and `\$` a dollar.
//
// It has to agree with the server exactly, or the preview shows a child a
// problem that is not the one they are sending. spec/fixtures/rich_content_cases.json
// is the agreement: RSpec runs it through the Ruby parser and, through node,
// through this one (spec/services/rich_content_spec.rb). So this file stays
// free of imports and of the DOM, which is what lets node load it on its own.

const DIGIT = /\d/

// RichContent::FRACTION is %r{(?<![\d,./√])(\d+)/(\d+)(?![\d/]|[.,]\d)}. The
// lookbehind is checked by hand below rather than written into the pattern:
// Safari only learned lookbehind in 16.4, and a regex literal an older iPad
// cannot parse is a syntax error that takes the whole module down with it.
const FRACTION = /(\d+)\/(\d+)(?![\d/]|[.,]\d)/g
const NOT_BEFORE = /[\d,./√]/

// RichContent::LATEX_TOKEN — the alternation order matters (`\$` first).
const LATEX_TOKEN = /\\\$|\$([^$\n]+)\$/g

// Ruby's String#blank?: nothing but Unicode white space. JavaScript's \s is a
// slightly different set (it has U+FEFF and lacks U+0085), so it is spelled out.
const BLANK = /^[\t\n\v\f\r \u0085\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000]*$/

function mathNode(latex) {
  return { type: "math", attrs: { latex } }
}

function textNode(text) {
  return { type: "text", text }
}

// RichContent.fraction_nodes. A match whose numerator is preceded by a digit,
// a comma, a dot, a slash or a root sign is not a fraction; Ruby would then try
// again one character later, so the scan resumes there too.
export function fractionNodes(text) {
  const nodes = []
  let consumed = 0
  FRACTION.lastIndex = 0
  let match
  while ((match = FRACTION.exec(text)) !== null) {
    if (match.index > 0 && NOT_BEFORE.test(text[match.index - 1])) {
      FRACTION.lastIndex = match.index + 1
      continue
    }
    if (match.index > consumed) nodes.push(textNode(text.slice(consumed, match.index)))
    nodes.push(mathNode(`\\frac{${match[1]}}{${match[2]}}`))
    consumed = match.index + match[0].length
  }
  if (consumed < text.length) nodes.push(textNode(text.slice(consumed)))
  return nodes
}

function latexInlineNodes(line) {
  const nodes = []
  let buffer = ""
  let consumed = 0
  LATEX_TOKEN.lastIndex = 0
  let match
  while ((match = LATEX_TOKEN.exec(line)) !== null) {
    buffer += line.slice(consumed, match.index)
    if (match[1] !== undefined) {
      nodes.push(...fractionNodes(buffer))
      buffer = ""
      nodes.push(mathNode(match[1]))
    } else {
      buffer += "$"
    }
    consumed = match.index + match[0].length
  }
  nodes.push(...fractionNodes(buffer + line.slice(consumed)))
  return nodes
}

// Ruby's split drops trailing empty strings ("a\n".split → ["a"]), and a
// textarea that ends in a newline is the commonest case there is.
function lines(text) {
  const parts = String(text ?? "").split(/\r?\n/)
  while (parts.length && parts[parts.length - 1] === "") parts.pop()
  return parts
}

export function parseAuthoring(text, { latex = false } = {}) {
  return {
    type: "doc",
    content: lines(text).map((line) => ({
      type: "paragraph",
      content: BLANK.test(line) ? [] : (latex ? latexInlineNodes(line) : fractionNodes(line))
    }))
  }
}

// RichContent::SIMPLE_FRACTION: the math nodes set as a .frac, not by KaTeX.
const SIMPLE_FRACTION = /^\\frac\{(-?\d+)\}\{(\d+)\}$/

// RichContent.render, as DOM rather than a string, for the same reason the
// server escapes: what a child typed is text and never markup. A fraction gets
// the three spans of RichContent.render_math, shared/_frac and lib/frac.js; any
// other formula gets the `math` controller's element, which is what fetches
// KaTeX — only once the first `$…$` appears.
export function renderDoc(doc, document = globalThis.document) {
  const fragment = document.createDocumentFragment()
  for (const paragraph of doc.content) {
    const p = document.createElement("p")
    for (const node of paragraph.content) {
      if (node.type === "text") {
        p.append(document.createTextNode(node.text))
      } else {
        p.append(renderMath(node.attrs.latex, document))
      }
    }
    fragment.append(p)
  }
  return fragment
}

function renderMath(latex, document) {
  const match = SIMPLE_FRACTION.exec(latex)
  if (match) {
    const frac = document.createElement("span")
    frac.className = "frac"
    frac.setAttribute("role", "math")
    frac.setAttribute("aria-label", `${match[1]}/${match[2]}`)
    for (const part of [match[1], match[2]]) {
      const span = document.createElement("span")
      span.textContent = part
      span.setAttribute("aria-hidden", "true")
      frac.append(span)
    }
    return frac
  }
  const span = document.createElement("span")
  span.dataset.controller = "math"
  span.dataset.mathLatexValue = latex
  span.textContent = latex
  return span
}

// Whether a digit sits right before the caret — the fraction key's question.
export function digitBefore(text, index) {
  return index > 0 && DIGIT.test(text[index - 1])
}
