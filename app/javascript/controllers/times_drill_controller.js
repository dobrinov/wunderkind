import { Controller } from "@hotwired/stimulus"

// „Бърза проверка" under the multiplication table: ten questions from one row
// (each factor once, shuffled) or from the whole table, four answers to pick
// from, and a score. Nothing is sent anywhere — it is a toy on a public page;
// the measured practice is behind the sign-up.
const LENGTH = 10

const shuffled = (list) => {
  const copy = [...list]
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[copy[i], copy[j]] = [copy[j], copy[i]]
  }
  return copy
}

export default class extends Controller {
  static targets = ["row", "bar", "question", "counter", "prompt", "option", "verdict", "next", "result", "resultRow", "score", "summary"]
  static values = { copy: Object }

  connect() {
    this.pick(7)
  }

  choose({ params: { row } }) {
    this.pick(Number(row))
  }

  // Sets the row and its button together: a page Turbo restores from its
  // snapshot comes back with whichever button was pressed when it was left,
  // while the drill itself starts over.
  pick(row) {
    this.row = row
    for (const key of this.rowTargets) key.setAttribute("aria-pressed", Number(key.dataset.timesDrillRowParam) === this.row)
    this.start()
  }

  restart() {
    this.start()
  }

  start() {
    this.questions = this.deal()
    this.index = 0
    this.score = 0
    this.questionTarget.hidden = false
    this.resultTarget.hidden = true
    this.ask()
  }

  // A row asks its ten factors once each; the whole table asks ten different
  // pairs from 2 to 9, since nobody needs checking on 1 × 6.
  deal() {
    if (this.row > 0) return shuffled([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]).map((b) => [this.row, b])

    const pairs = []
    for (let a = 2; a <= 9; a++) for (let b = 2; b <= 9; b++) pairs.push([a, b])
    return shuffled(pairs).slice(0, LENGTH)
  }

  ask() {
    const [a, b] = this.questions[this.index]
    this.answerValue = a * b
    this.answered = false

    this.counterTarget.textContent = this.fill(this.copyValue.counter, { number: this.index + 1, score: this.score })
    this.promptTarget.textContent = `${a} × ${b} = ?`
    this.verdictTarget.textContent = ""
    this.nextTarget.hidden = true
    this.barTarget.style.width = `${this.index * 10}%`

    const options = this.options(a, b)
    this.optionTargets.forEach((button, i) => {
      button.textContent = options[i]
      button.disabled = false
      button.classList.remove("is-correct", "is-wrong")
      button.setAttribute("aria-pressed", false)
    })
  }

  // The right product and three wrong ones a child might really give: a
  // neighbour in the same row or column, or one off.
  options(a, b) {
    const right = a * b
    const near = shuffled([right + a, right - a, right + b, right - b, (a + 1) * (b + 1), right + 1, right - 1, right + 10])
    const wrong = [...new Set(near)].filter((value) => value > 0 && value !== right).slice(0, 3)
    return shuffled([right, ...wrong])
  }

  answer({ currentTarget }) {
    if (this.answered) return
    this.answered = true

    const [a, b] = this.questions[this.index]
    const right = Number(currentTarget.textContent) === this.answerValue
    if (right) this.score += 1
    this.counterTarget.textContent = this.fill(this.copyValue.counter, { number: this.index + 1, score: this.score })

    for (const button of this.optionTargets) {
      const correct = Number(button.textContent) === this.answerValue
      button.disabled = true
      button.classList.toggle("is-correct", correct)
      button.classList.toggle("is-wrong", button === currentTarget && !right)
    }
    currentTarget.setAttribute("aria-pressed", true)

    this.verdictTarget.textContent = right ? this.copyValue.right : this.fill(this.copyValue.wrong, { a, b, product: this.answerValue })
    this.verdictTarget.classList.toggle("text-green-700", right)
    this.verdictTarget.classList.toggle("text-red-700", !right)
    this.barTarget.style.width = `${(this.index + 1) * 10}%`
    this.nextTarget.hidden = false
    this.nextTarget.focus()
  }

  next() {
    this.index += 1
    if (this.index < LENGTH) return this.ask()

    const copy = this.copyValue
    this.questionTarget.hidden = true
    this.resultTarget.hidden = false
    this.resultRowTarget.textContent = this.row > 0 ? this.fill(copy.row, { row: this.row }) : copy.whole
    this.scoreTarget.textContent = this.fill(copy.score, { score: this.score })
    this.summaryTarget.textContent = this.score === LENGTH ? copy.perfect : this.score >= 7 ? copy.close : copy.again
  }

  fill(text, values) {
    return Object.entries(values).reduce((line, [key, value]) => line.replace(`%{${key}}`, value), text)
  }
}
