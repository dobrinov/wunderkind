// node --test spec/javascript/calculators.test.mjs — run by
// spec/javascript/calculators_spec.rb, which hands it every calculator page
// (config/calculators/*.yml) as JSON in CALCULATORS.
//
// A page shows a worked example as text before its script runs, and the
// script then writes the working for the same starting numbers. This holds
// the two to each other, in both languages, and walks every slider to both
// ends to see that no combination draws a figure made of NaN.
import { test } from "node:test"
import assert from "node:assert/strict"
import shapes from "../../app/javascript/lib/calculators/index.js"

import { kindOf } from "../../app/javascript/lib/calculators/triangle.js"

// The triangle says what kind it is, and that is about its angles — all
// three, not only the two at the base.
test("triangle: acute, right-angled or obtuse by its angles", () => {
  assert.equal(kindOf(12, 7, 4.2), "acute")
  assert.equal(kindOf(12, 7, 0), "right_angled")
  assert.equal(kindOf(12, 7, 12), "right_angled")
  assert.equal(kindOf(12, 7, -2), "obtuse")
  assert.equal(kindOf(12, 7, 14), "obtuse")
  // The height lands inside the base, and the angle at the apex is the one
  // that is not acute: flat and wide, or exactly a half-square.
  assert.equal(kindOf(20, 1, 10), "obtuse")
  assert.equal(kindOf(20, 4, 4), "obtuse")
  assert.equal(kindOf(10, 5, 5), "right_angled")
  assert.equal(kindOf(10, 6, 5), "acute")
})

// A rounded value never follows an equals sign.
test("a third is approximate, a whole is exact, and one π is just π", () => {
  const ctx = { fmt: formatter(","), copy: { unit: "см", area_unit: "см²", volume_unit: "см³" } }

  assert.match(shapes.konus.radius({ r: 1, h: 1 }, ctx).steps[0], /\/ 3 ≈ 0,33π ≈ 1,05/)
  assert.match(shapes.konus.radius({ r: 3, h: 4 }, ctx).steps[0], /\/ 3 = 12π/)
  assert.match(shapes.kalbo.radius({ r: 1 }, ctx).steps[0], /≈ 1,33π/)
  assert.match(shapes.piramida.base({ B: 4, h: 1 }, ctx).steps[0], /≈ 1,33 см³/)
  assert.match(shapes["litse-na-krag"].radius({ r: 1 }, ctx).steps[0], /= π ≈ 3,14/)
  assert.match(shapes["litse-na-romb"].diagonals({ p: 20, q: 14 }, ctx).steps[1], /a = √\(10² \+ 7²\) ≈ 12,21/)
  assert.match(shapes["litse-na-triagalnik"].heron({ a: 1, b: 1, c: 1 }, { ...ctx, copy: { ...ctx.copy } }).steps[2], /√0,1875 ≈ 0,43/)
})

const calculators = JSON.parse(process.env.CALCULATORS)
const formatter = (decimal) => (value, digits = 2) => String(Math.round(value * 10 ** digits) / 10 ** digits).replace(".", decimal)

for (const calculator of calculators) {
  const shape = shapes[calculator.slug]

  test(`${calculator.slug}: has a function for every mode`, () => {
    assert.ok(shape, "no module registered")
    for (const mode of calculator.modes) assert.equal(typeof shape[mode.key], "function", mode.key)
  })

  for (const [locale, decimal] of [["bg", ","], ["en", "."]]) {
    const copy = calculator[locale].copy

    for (const mode of calculator.modes) {
      test(`${calculator.slug}/${mode.key} (${locale}): the example on the page is the script's own working`, () => {
        const values = Object.fromEntries(mode.inputs.map((input) => [input.key, input.value]))
        const result = shape[mode.key](values, { fmt: formatter(decimal), copy })

        assert.equal(result.steps.join("\n"), calculator[locale].modes[mode.key].example)
        assert.ok(result.svg.length > 0, "no figure")
      })
    }
  }

  for (const mode of calculator.modes) {
    test(`${calculator.slug}/${mode.key}: draws at every end of every slider`, () => {
      const copy = calculator.bg.copy
      const ends = mode.inputs.reduce((combos, input) => combos.flatMap((combo) => [input.min, input.max].map((value) => ({ ...combo, [input.key]: value }))), [{}])

      for (const values of ends) {
        const result = shape[mode.key](values, { fmt: formatter(","), copy })
        const text = result.steps.join(" ") + result.svg
        assert.ok(!/NaN|undefined|Infinity/.test(text), `${JSON.stringify(values)} → ${text.slice(0, 200)}`)
        assert.ok(result.invalid || result.svg.length > 0, `${JSON.stringify(values)} drew nothing`)
      }
    })
  }
}
