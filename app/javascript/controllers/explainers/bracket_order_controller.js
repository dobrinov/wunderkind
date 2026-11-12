import { Controller } from "@hotwired/stimulus"

// „Ред на действията": a fixed set of expressions worked one operation at a
// time. Each press picks the operation the rules say comes next — inside the
// brackets first, then multiplication and division, otherwise the leftmost —
// writes the shorter expression on a new line and names the rule. The
// expressions are fixed rather than random because each one is there to show
// one thing: the same numbers with and without brackets, and two that plain
// left-to-right gets right for a reason worth saying. Every one of them
// stays in whole, non-negative numbers at every step.
const EXPRESSIONS = [
  [48, "-", 6, "*", 5],
  ["(", 48, "-", 6, ")", "*", 5],
  [20, "-", 8, "+", 3],
  [20, "-", "(", 8, "+", 3, ")"],
  [36, "/", 4, "*", 3]
]
const STRONG = ["*", "/"]
const OPERATIONS = ["+", "-", "*", "/"]

const compute = (left, operation, right) => ({ "+": left + right, "-": left - right, "*": left * right, "/": left / right })[operation]

// The operation whose turn it is: where it stands among the tokens, and the
// rule that chose it. The expressions hold at most one pair of brackets.
const pick = (tokens) => {
  const open = tokens.indexOf("(")
  const from = open === -1 ? 0 : open + 1
  const to = open === -1 ? tokens.length : tokens.indexOf(")")
  const places = []
  for (let index = from; index < to; index++) if (OPERATIONS.includes(tokens[index])) places.push(index)
  const strong = places.filter((index) => STRONG.includes(tokens[index]))
  const at = strong.length ? strong[0] : places[0]
  const rule = open !== -1 ? "brackets"
    : places.length === 1 ? "last"
      : strong.length && strong.length < places.length ? "muldiv"
        : strong.length ? "left_to_right_muldiv" : "left_to_right_addsub"
  return { at, rule, open, close: to }
}

// One step: the tokens after it, which old tokens it used and where the
// result stands among the new ones.
const advance = (tokens) => {
  const { at, rule, open, close } = pick(tokens)
  const value = compute(tokens[at - 1], tokens[at], tokens[at + 1])
  // Brackets left holding one number are dropped with the step.
  const closes = open !== -1 && close - open === 4
  const [first, last] = closes ? [open, close] : [at - 1, at + 1]
  const after = [...tokens.slice(0, first), value, ...tokens.slice(last + 1)]
  return { after, rule, value, used: [first, last], result: first, step: [tokens[at - 1], tokens[at], tokens[at + 1]] }
}

// What working strictly from left to right, brackets ignored, would give.
const leftToRight = (tokens) => {
  const flat = tokens.filter((token) => token !== "(" && token !== ")")
  let value = flat[0]
  for (let index = 1; index < flat.length; index += 2) value = compute(value, flat[index], flat[index + 1])
  return value
}

export default class extends Controller {
  static targets = ["choice", "lines", "note", "done", "wrong", "step"]
  static values = { copy: Object }

  connect() {
    this.choiceTargets.forEach((button, index) => { button.textContent = this.text(EXPRESSIONS[index]) })
    // The article's own example first: 48 − 6 · 5.
    this.start(0)
  }

  choose(event) {
    this.start(Number(event.params.index))
  }

  next() {
    const current = this.lines[this.lines.length - 1]
    if (current.tokens.length === 1) return this.start(this.index)

    const { after, rule, value, used, result, step } = advance(current.tokens)
    current.hot = used
    this.lines.push({ tokens: after, hot: [result, result] })
    this.note = this.copyValue[rule].replaceAll("%{step}", `${this.text(step)} = ${value}`)
    this.render()
  }

  start(index) {
    this.index = index
    this.lines = [{ tokens: EXPRESSIONS[index], hot: null }]
    this.note = this.copyValue.start
    this.render()
  }

  render() {
    const copy = this.copyValue
    const expression = EXPRESSIONS[this.index]
    const last = this.lines[this.lines.length - 1].tokens
    const finished = last.length === 1
    const wrong = leftToRight(expression)

    this.choiceTargets.forEach((button, index) => button.setAttribute("aria-pressed", String(index === this.index)))
    this.linesTarget.replaceChildren(...this.lines.map((line, index) => this.line(line, index > 0)))
    this.noteTarget.textContent = this.note
    this.stepTarget.textContent = finished ? copy.again : copy.next

    this.doneTarget.hidden = !finished
    this.doneTarget.textContent = finished ? copy.done.replaceAll("%{expression}", this.text(expression)).replaceAll("%{result}", last[0]) : ""
    const differs = finished && wrong !== last[0]
    this.wrongTarget.hidden = !differs
    this.wrongTarget.textContent = differs ? copy.wrong.replaceAll("%{wrong}", wrong) : ""
  }

  // One line of the working: the tokens the step used (or made) in indigo.
  line({ tokens, hot }, continued) {
    const row = document.createElement("p")
    if (continued) row.append("= ")
    tokens.forEach((token, index) => {
      if (index > 0 && tokens[index - 1] !== "(" && token !== ")") row.append(" ")
      const piece = document.createElement("span")
      piece.textContent = this.sign(token)
      if (hot && index >= hot[0] && index <= hot[1]) piece.className = "text-primary-600"
      row.append(piece)
    })
    return row
  }

  text(tokens) {
    return tokens.map((token, index) => (index > 0 && tokens[index - 1] !== "(" && token !== ")" ? " " : "") + this.sign(token)).join("")
  }

  sign(token) {
    return { "-": "−", "*": "·", "/": this.copyValue.divide }[token] ?? String(token)
  }
}
