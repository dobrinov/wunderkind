// node --test spec/javascript/speakable.test.mjs — run by spec/javascript/speakable_spec.rb.
import { test } from "node:test"
import assert from "node:assert/strict"
import { speakable } from "../../app/javascript/lib/speakable.js"

const cases = [
  [ "Колко е 3/4 от 20?", "Колко е 3 върху 4 от 20?" ],
  [ "7 · 8 = ?", "7 по 8 равно на ?" ],
  [ "12 : 4", "12 делено на 4" ],
  [ "15 − 6 + 2", "15 минус 6 плюс 2" ],
  [ "Числото е -5.", "Числото е минус 5." ],
  [ "x² + 3³", "x на квадрат плюс 3 на куб" ],
  [ "√16", "корен от 16" ],
  [ "2π", "2 пи" ],
  [ "25% от 40", "25 процента от 40" ],
  [ "ъгъл от 90°", "ъгъл от 90 градуса" ],
  [ "a ≤ b, c ≥ d, e ≠ f", "a по-малко или равно на b, c по-голямо или равно на d, e различно от f" ],
  [ "3 < 5 > 1", "3 по-малко от 5 по-голямо от 1" ],
  // A hyphenated word is not a subtraction.
  [ "по-голямо", "по-голямо" ]
]

for (const [ written, said ] of cases) {
  test(written, () => assert.equal(speakable(written), said))
}

import { latexToText } from "../../app/javascript/lib/speakable.js"

test("a KaTeX formula reads by its source", () => {
  assert.equal(speakable(latexToText("\\frac{x+1}{2} \\cdot \\sqrt{9}")), "(x плюс 1) върху 2 по корен от 9")
  assert.equal(speakable(latexToText("x^2 - 2^{10}")), "x на квадрат минус 2 на степен 10")
})
