import { Controller } from "@hotwired/stimulus"

// „Как се решава логическа задача": one fixed puzzle on a three-by-three grid.
// Rows are the children, columns the pets (cat, dog, parrot). The three clues
// each forbid one cell, and together they leave exactly one assignment —
// checked by brute force over the six permutations, with each clue needed.
// The reader taps a cell through empty → ✕ → ✓. „Провери" names the first
// thing wrong (two ✓ in a line, a ✓ a clue forbids, a ✓ or ✕ that cannot be
// right) without giving the answer away; „Покажи как" lays down the marks
// each clue justifies, one clue per press.
const EMPTY = 0, NO = 1, YES = 2
const MARKS = ["", "✕", "✓"]
const STATES = ["state_empty", "state_no", "state_yes"]

// The cell each clue rules out, as [row, column], and the one solution:
// SOLUTION[row] is the column holding that row's ✓.
const FORBIDDEN = [[0, 2], [2, 2], [2, 1]]
const SOLUTION = [1, 2, 0]

// What each clue allows to be marked, as [row, column, mark].
const STEPS = [
  [[0, 2, NO]],
  [[2, 2, NO], [1, 2, YES], [1, 0, NO], [1, 1, NO]],
  [[2, 1, NO], [2, 0, YES], [0, 0, NO], [0, 1, YES]]
]

const TONES = {
  good: ["bg-green-100", "text-green-800"],
  bad: ["bg-red-50", "text-red-900"],
  plain: ["bg-primary-50", "text-primary-900"]
}

export default class extends Controller {
  static targets = ["cell", "clue", "show", "step", "result"]
  static values = { copy: Object }

  connect() {
    this.clear()
  }

  clear() {
    this.grid = [[EMPTY, EMPTY, EMPTY], [EMPTY, EMPTY, EMPTY], [EMPTY, EMPTY, EMPTY]]
    this.step = 0
    this.say(null)
    this.explain(null)
    this.render()
  }

  mark({ params: { row, column } }) {
    this.grid[row][column] = (this.grid[row][column] + 1) % 3
    this.say(null)
    this.explain(null)
    this.render()
  }

  // The next clue of the worked solution. The first press starts from an
  // empty grid, so the walk never builds on the reader's own marks.
  show() {
    if (this.step === 0) this.grid = this.grid.map(() => [EMPTY, EMPTY, EMPTY])
    for (const [row, column, mark] of STEPS[this.step]) this.grid[row][column] = mark
    this.say(null)
    this.explain(this.copyValue.steps[this.step])
    this.step = (this.step + 1) % STEPS.length
    this.render(this.step === 0 ? STEPS.length - 1 : this.step - 1)
  }

  check() {
    const copy = this.copyValue
    const [key, tone] = this.verdict()
    this.say(copy[key].replaceAll("%{k}", this.brokenClue() + 1), tone)
  }

  // The first thing wrong with the grid, or how far it has got.
  verdict() {
    const yes = (row, column) => this.grid[row][column] === YES
    const lines = [0, 1, 2]
    const doubled = lines.some((i) => lines.filter((j) => yes(i, j)).length > 1 || lines.filter((j) => yes(j, i)).length > 1)
    if (doubled) return ["result_two", "bad"]
    if (this.brokenClue() >= 0) return ["result_clue", "bad"]
    if (lines.some((row) => lines.some((column) => yes(row, column) && SOLUTION[row] !== column))) return ["result_wrong_yes", "bad"]
    if (lines.some((row) => this.grid[row][SOLUTION[row]] === NO)) return ["result_wrong_no", "bad"]
    if (lines.every((row) => yes(row, SOLUTION[row]))) return ["result_done", "good"]
    return ["result_partial", "plain"]
  }

  // The index of the first clue a ✓ sits against, or -1.
  brokenClue() {
    return FORBIDDEN.findIndex(([row, column]) => this.grid[row][column] === YES)
  }

  // The walkthrough's line, shown between the clues and the grid.
  explain(text) {
    this.stepTarget.hidden = !text
    this.stepTarget.textContent = text || ""
  }

  // The verdict of „Провери", shown under the buttons.
  say(text, tone) {
    const result = this.resultTarget
    result.hidden = !text
    result.textContent = text || ""
    for (const [name, classes] of Object.entries(TONES)) classes.forEach((item) => result.classList.toggle(item, name === tone))
  }

  // `clue` is the clue the walk has just applied, if any.
  render(clue = -1) {
    const copy = this.copyValue
    this.cellTargets.forEach((cell, index) => {
      const row = Math.floor(index / 3), column = index % 3
      const state = this.grid[row][column]
      cell.textContent = MARKS[state]
      cell.setAttribute("aria-label", copy.cell.replaceAll("%{child}", copy.children[row])
        .replaceAll("%{pet}", copy.pets[column]).replaceAll("%{state}", copy[STATES[state]]))
      cell.classList.toggle("bg-green-100", state === YES)
      cell.classList.toggle("text-green-800", state === YES)
      cell.classList.toggle("bg-ink-100", state === NO)
      cell.classList.toggle("text-ink-500", state === NO)
    })
    this.clueTargets.forEach((item, index) => item.classList.toggle("bg-primary-100", index === clue))
    this.showTarget.textContent = this.step === 0 ? copy.show : copy.next
  }
}
