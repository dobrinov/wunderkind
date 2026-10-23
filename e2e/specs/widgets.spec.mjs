import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

// The seven "showing the working" widgets, each driven the way a child would:
// taps on the controls the widget draws, the keyboard where it offers one.
//
// Every widget gets two journeys on two accounts (see lib/tasks/e2e.rake,
// seed_widgets): one answered right, one answered wrong. The right one also
// presses „Провери" while the answer is still unfinished first — the hidden
// state is empty then, so the server refuses it as blank and hands the same,
// still unanswered question back. That is what "incomplete" means here: not a
// disabled button (none of the widgets disable it) but a submission that
// costs nothing and grades nothing. The wrong one reads the feedback card's
// „Верен отговор" chip, which is Widgets.solution_display (or display) on the
// stored solution — the one place the student is told what the widget wanted.
//
// The accounts have feedback_after_answer on, so the verdict is rendered on
// the question's own page, and sound on (the default), so the answer goes up
// by fetch — `check` waits for that POST, as answerQuestion does.

const BLANK = "Отговорът ти не стигна до нас. Опитай отново."

async function openWidget(page, key, { wrong = false, phone = false } = {}) {
  await signIn(page, `widget-${key}${wrong ? "-wrong" : phone ? "-phone" : ""}@e2e.test`)
  await page.goto("/assignments")
  await page.getByRole("link", { name: "Продължи" }).click()
  await page.waitForURL(/\/questions\/\d+/)
  const widget = page.locator(`[data-controller="widget-${key.replaceAll("_", "-")}"]`)
  await expect(widget).toBeVisible()
  return widget
}

const state = (page) => page.locator('input[type="hidden"][name="state"]')

async function check(page) {
  await Promise.all([
    page.waitForResponse((response) =>
      response.request().method() === "POST" && response.url().includes("/answer")),
    page.getByRole("button", { name: "Провери" }).click()
  ])
}

// Pressing „Провери" on an unfinished answer: refused, nothing recorded, the
// same question back and still answerable.
async function checkRefusedAsBlank(page, key) {
  await expect(state(page)).toHaveValue("")
  await check(page)
  await expect(page.getByText(BLANK)).toBeVisible()
  await expect(page.locator(".fb-card")).toHaveCount(0)
  await expect(page.locator(`[data-controller="widget-${key.replaceAll("_", "-")}"]`)).toBeVisible()
}

async function expectCorrect(page) {
  await expect(page.locator(".fb-card.fb-correct")).toBeVisible()
  await expect(page.locator(".fb-title")).toHaveText("Вярно!")
}

async function expectWrong(page, { yours, correct }) {
  await expect(page.locator(".fb-card.fb-wrong")).toBeVisible()
  await expect(page.locator(".fb-title")).toHaveText("Не е вярно")
  await expect(page.locator(".fb-chip-yours .fb-chip-value")).toHaveText(yours)
  await expect(page.locator(".fb-chip-correct .fb-chip-value")).toHaveText(correct)
}

test.describe("column_arithmetic — 144 − 105 in columns", () => {
  const cell = (widget, place) => widget.getByRole("button", { name: `Цифра на резултата: ${place}`, exact: true })
  const key = (widget, digit) => widget.getByRole("button", { name: digit, exact: true })

  test("written right to left, with a borrow noted, is right", async ({ page }) => {
    const widget = await openWidget(page, "column_arithmetic")

    // A tens digit with the ones still empty is a gap, not an answer.
    await cell(widget, "десетици").click()
    await key(widget, "3").click()
    await expect(state(page)).toHaveValue("")
    await checkRefusedAsBlank(page, "column_arithmetic")

    // The selection starts on the ones and walks left as digits go in.
    await expect(cell(widget, "единици")).toHaveAttribute("aria-pressed", "true")
    await key(widget, "9").click()
    await expect(cell(widget, "единици")).toHaveText("9")
    await expect(cell(widget, "десетици")).toHaveAttribute("aria-pressed", "true")
    // …and from the keyboard, the way a child with a laptop would.
    await page.keyboard.press("3")
    await expect(cell(widget, "десетици")).toHaveText("3")

    // The borrow over the ones is the child's own working, not graded.
    await widget.getByRole("button", { name: "Помощна клетка над единици" }).click()
    await key(widget, "1").click()
    await key(widget, "4").click()
    await expect(widget.getByRole("button", { name: "Помощна клетка над единици" })).toHaveText("14")

    expect(JSON.parse(await state(page).inputValue())).toEqual({ result: "39", helpers: { 0: "14" } })
    await check(page)
    await expectCorrect(page)
  })

  test("a subtraction that forgot to borrow is wrong, and shows 39", async ({ page }) => {
    const widget = await openWidget(page, "column_arithmetic", { wrong: true })

    await key(widget, "1").click()
    await key(widget, "7").click()
    // A wrong digit can be gone back to, erased and rewritten.
    await cell(widget, "десетици").click()
    await key(widget, "Изтрий").click()
    await expect(cell(widget, "десетици")).toHaveText("")
    await key(widget, "4").click()
    await expect(cell(widget, "десетици")).toHaveText("4")

    await check(page)
    await expectWrong(page, { yours: "41", correct: "39" })
  })
})

test.describe("balance_scale — 3x + 4 = x + 16", () => {
  const row = (widget, label) =>
    widget.locator("div").filter({ has: widget.page().getByText(label, { exact: true }) }).last()

  test("doing the same to both pans until x is alone, then x = 6, is right", async ({ page }) => {
    const widget = await openWidget(page, "balance_scale")
    const chain = widget.locator('[data-widget-balance-scale-target="chain"]')
    await expect(chain).toHaveText("3x + 4 = x + 16")

    // Halving 3x + 4 is not a move a scale can make, and it says so.
    await row(widget, "Раздели двете страни на").getByRole("button", { name: "Направи" }).click()
    await expect(widget.getByRole("alert")).toBeVisible()
    await expect(chain).toHaveText("3x + 4 = x + 16")

    await row(widget, "Махни x от двете страни").getByRole("button", { name: "Направи" }).click()
    await expect(widget.getByRole("alert")).toBeHidden()
    const units = row(widget, "Махни от двете страни")
    for (let i = 0; i < 3; i += 1) await units.getByRole("button", { name: "+1" }).click()
    await expect(units.locator('[data-widget-balance-scale-target="k"]')).toHaveText("4")
    await units.getByRole("button", { name: "Направи" }).click()
    await row(widget, "Раздели двете страни на").getByRole("button", { name: "Направи" }).click()
    await expect(chain).toHaveText("3x + 4 = x + 16 → 2x + 4 = 16 → 2x = 12 → x = 6")

    // The moves alone are not an answer: x has to be written.
    await expect(state(page)).toHaveValue("")
    await checkRefusedAsBlank(page, "balance_scale")

    // The refused blank reloaded the page, so the working starts over —
    // undo is exercised on the way.
    await row(widget, "Махни x от двете страни").getByRole("button", { name: "Направи" }).click()
    await widget.getByRole("button", { name: "Назад" }).click()
    await expect(chain).toHaveText("3x + 4 = x + 16")
    await expect(widget.getByRole("button", { name: "Назад" })).toBeDisabled()
    await row(widget, "Махни x от двете страни").getByRole("button", { name: "Направи" }).click()

    await widget.getByRole("textbox").fill("6")
    expect(JSON.parse(await state(page).inputValue())).toEqual({ steps: [ { op: "x", k: 1 } ], x: "6" })
    await check(page)
    await expectCorrect(page)
  })

  test("a wrong x is wrong, and the chip says x = 6", async ({ page }) => {
    const widget = await openWidget(page, "balance_scale", { wrong: true })
    await row(widget, "Махни x от двете страни").getByRole("button", { name: "Направи" }).click()
    await widget.getByRole("textbox").fill("8")

    await check(page)
    await expectWrong(page, { yours: "3x + 4 = x + 16 → 2x + 4 = 16 → x = 8", correct: "x = 6" })
  })
})

test.describe("geoboard — a rectangle of area 2 and perimeter 6 on 9 × 9", () => {
  const peg = (widget, col, row) => widget.getByRole("button", { name: new RegExp(`^Точка ${col}, ${row}( |$)`) })
  const stat = (widget, label) => widget.locator('[data-widget-geoboard-target="readout"] > div', { hasText: label }).locator("span").last()

  async function draw(widget, corners) {
    for (const [col, row] of corners) await peg(widget, col, row).click()
  }

  test("tapping four corners and closing on the first is right", async ({ page }) => {
    const widget = await openWidget(page, "geoboard")
    await expect(widget.getByRole("button", { name: /^Точка / })).toHaveCount(81)

    // An open path has no area: nothing to submit until the shape is closed.
    await draw(widget, [ [ 4, 4 ], [ 6, 4 ], [ 6, 5 ], [ 4, 5 ] ])
    await expect(stat(widget, "Върхове")).toHaveText("4")
    await expect(stat(widget, "Лице")).toHaveText("—")
    await checkRefusedAsBlank(page, "geoboard")

    await draw(widget, [ [ 4, 4 ], [ 6, 4 ], [ 6, 5 ] ])
    // A mis-tap is taken back, not restarted.
    await peg(widget, 9, 9).click()
    await widget.getByRole("button", { name: "Назад" }).click()
    await peg(widget, 4, 5).click()
    await expect(peg(widget, 4, 4)).toHaveAccessibleName(/затвори фигурата/)
    await peg(widget, 4, 4).click()

    await expect(stat(widget, "Лице")).toHaveText("2")
    await expect(stat(widget, "Обиколка")).toHaveText("6")
    expect(JSON.parse(await state(page).inputValue())).toEqual({ points: [ [ 3, 3 ], [ 5, 3 ], [ 5, 4 ], [ 3, 4 ] ] })
    await check(page)
    await expectCorrect(page)
  })

  test("a square of area 4 is wrong, and the chip names the rectangle", async ({ page }) => {
    const widget = await openWidget(page, "geoboard", { wrong: true })
    await draw(widget, [ [ 1, 1 ], [ 3, 1 ], [ 3, 3 ], [ 1, 3 ], [ 1, 1 ] ])
    await expect(stat(widget, "Лице")).toHaveText("4")

    await check(page)
    await expectWrong(page, { yours: "4 върха, лице 4, обиколка 8", correct: "правоъгълник, лице 2, обиколка 6" })
  })
})

test.describe("unit_circle — every α with cos α = √2/2", () => {
  const add = (widget) => widget.getByRole("button", { name: /^Добави / })

  test("picking 45° and 315° — one by its peg, one by a tap beside the circle — is right", async ({ page }) => {
    const widget = await openWidget(page, "unit_circle")
    await expect(add(widget)).toBeDisabled()
    await checkRefusedAsBlank(page, "unit_circle")

    await widget.getByRole("button", { name: "45 градуса", exact: true }).click()
    await expect(widget.locator('[data-widget-unit-circle-target="readout"]')).toHaveText("45°")
    await add(widget).click()
    await expect(add(widget)).toBeDisabled() // already added

    // A press just outside the circle, away from any peg, picks the nearest one.
    const board = widget.locator('[data-widget-unit-circle-target="canvas"] > div')
    const box = await board.boundingBox()
    const radius = (155 / 340) * box.width
    const angle = (315 * Math.PI) / 180
    await page.mouse.click(box.x + box.width / 2 + radius * Math.cos(angle), box.y + box.height / 2 - radius * Math.sin(angle))
    await expect(widget.locator('[data-widget-unit-circle-target="readout"]')).toHaveText("315°")
    await add(widget).click()

    // An angle added by mistake comes off its chip.
    await widget.getByRole("button", { name: "90 градуса", exact: true }).click()
    await add(widget).click()
    await widget.getByRole("button", { name: "Махни 90°" }).click()
    await expect(widget.getByRole("button", { name: /^Махни / })).toHaveCount(2)

    expect(JSON.parse(await state(page).inputValue())).toEqual({ angles: [ 45, 315 ] })
    await check(page)
    await expectCorrect(page)
  })

  test("only one of the two angles is wrong, and the chip lists both", async ({ page }) => {
    const widget = await openWidget(page, "unit_circle", { wrong: true })
    // From the keyboard: the arrows walk the pegs 15° at a time.
    await widget.getByRole("button", { name: "30 градуса", exact: true }).click()
    await page.keyboard.press("ArrowUp")
    await expect(widget.locator('[data-widget-unit-circle-target="readout"]')).toHaveText("45°")
    await add(widget).click()

    await check(page)
    await expectWrong(page, { yours: "45°", correct: "45°, 315°" })
  })
})

test.describe("find_mistake — 2/11 + 9/11 added wrong", () => {
  const lines = (widget) => widget.getByRole("button")

  test("pointing at the line that adds the denominators is right", async ({ page }) => {
    const widget = await openWidget(page, "find_mistake")
    // The problem itself is line 0 and is not something to point at.
    await expect(lines(widget)).toHaveCount(2)
    await checkRefusedAsBlank(page, "find_mistake")

    await lines(widget).nth(1).click()
    await expect(lines(widget).nth(1)).toHaveAttribute("aria-pressed", "true")
    await page.keyboard.press("ArrowUp")
    await expect(lines(widget).nth(0)).toHaveAttribute("aria-pressed", "true")
    await expect(lines(widget).nth(1)).toHaveAttribute("aria-pressed", "false")

    expect(JSON.parse(await state(page).inputValue())).toEqual({ line: 1 })
    await check(page)
    await expectCorrect(page)
  })

  test("pointing at the line that only carries it on is wrong", async ({ page }) => {
    const widget = await openWidget(page, "find_mistake", { wrong: true })
    await lines(widget).nth(1).click()

    await check(page)
    await expectWrong(page, { yours: "= 1/2", correct: "= (2 + 9)/(11 + 11)" })
  })
})

test.describe("number_hops — 18 − 6 in hops", () => {
  const hop = (widget, size) => widget.getByRole("button", { name: `−${size}`, exact: true })
  const chip = (widget) => widget.locator('[data-widget-number-hops-target="chip"]')

  test("hops that make −6 and a landing of 12 are right", async ({ page }) => {
    const widget = await openWidget(page, "number_hops")
    // A hop longer than the whole trip is not on offer.
    await expect(hop(widget, 10)).toBeDisabled()
    await expect(chip(widget)).toHaveText("остават 6")

    await hop(widget, 5).click()
    await expect(chip(widget)).toHaveText("остават 1")
    await expect(hop(widget, 2)).toBeDisabled()
    await expect(hop(widget, 5)).toBeDisabled()
    // A landing written before the hops add up is not an answer yet.
    await widget.getByRole("textbox").fill("12")
    await checkRefusedAsBlank(page, "number_hops")

    await hop(widget, 2).click()
    await hop(widget, 2).click()
    await expect(chip(widget)).toHaveText("остават 2")
    await widget.getByRole("button", { name: "Назад" }).click()
    await widget.getByRole("button", { name: "Назад" }).click()
    await hop(widget, 5).click()
    await hop(widget, 1).click()
    await expect(chip(widget)).toHaveText("точно")
    await expect(hop(widget, 1)).toBeDisabled()
    await expect(state(page)).toHaveValue("")
    await widget.getByRole("textbox").fill("12")

    expect(JSON.parse(await state(page).inputValue())).toEqual({ hops: [ -5, -1 ], value: "12" })
    await check(page)
    await expectCorrect(page)
  })

  test("the right hops and the wrong landing are wrong, and the chip says 12", async ({ page }) => {
    const widget = await openWidget(page, "number_hops", { wrong: true })
    await hop(widget, 5).click()
    await hop(widget, 1).click()
    await widget.getByRole("textbox").fill("13")

    await check(page)
    await expectWrong(page, { yours: "18 − 5 − 1 = 13", correct: "12" })
  })
})

test.describe("inequality_line — 2x + 1 < 12 on a line in halves", () => {
  const tick = (widget, value) => widget.getByRole("button", { name: `Граница ${value}`, exact: true })
  const readout = (widget) => widget.locator('[data-widget-inequality-line-target="readout"]')

  test("an open dot at 5,5 running left is right", async ({ page }) => {
    const widget = await openWidget(page, "inequality_line")
    await expect(widget.getByRole("button", { name: /^Граница / })).toHaveCount(13)

    // Two of the three choices are not an answer.
    await tick(widget, "5").click()
    await widget.getByRole("button", { name: "невключена" }).click()
    await expect(readout(widget)).toHaveText("")
    await checkRefusedAsBlank(page, "inequality_line")

    await tick(widget, "5").click()
    // The arrow keys move the boundary along the line, a half at a time.
    await page.keyboard.press("ArrowRight")
    await expect(tick(widget, "5,5")).toHaveAttribute("aria-pressed", "true")
    await widget.getByRole("button", { name: "невключена" }).click()
    await expect(state(page)).toHaveValue("")
    await widget.getByRole("button", { name: "← към −∞" }).click()
    await expect(readout(widget)).toHaveText("x < 5,5")

    expect(JSON.parse(await state(page).inputValue())).toEqual({ edge: 5.5, closed: false, direction: "left" })
    await check(page)
    await expectCorrect(page)
  })

  test("a filled dot is wrong, and the chip says x < 5,5", async ({ page }) => {
    const widget = await openWidget(page, "inequality_line", { wrong: true })
    await tick(widget, "5,5").click()
    await widget.getByRole("button", { name: "включена", exact: true }).click()
    await widget.getByRole("button", { name: "← към −∞" }).click()
    await expect(readout(widget)).toHaveText("x ≤ 5,5")

    await check(page)
    await expectWrong(page, { yours: "x ≤ 5,5", correct: "x < 5,5" })
  })
})

// At phone width, the dense widgets put their targets closer together than a
// fingertip. What matters is not the size of each button but that a tap on
// the mark a child is aiming at selects that mark — so these tap the visible
// mark itself (the dot, the tick) rather than the centre of its button, which
// is what Playwright's click would do and which hides the problem.
test.describe("at phone width, a tap lands on the mark under the finger", () => {
  test.use({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true })

  test("geoboard 9 × 9: every peg along a row and a column", async ({ page }) => {
    const widget = await openWidget(page, "geoboard", { phone: true })
    for (const [col, row] of [ ...[ 1, 2, 3, 4, 5, 6, 7, 8, 9 ].map((c) => [ c, 5 ]), ...[ 1, 2, 3, 4, 6, 7, 8, 9 ].map((r) => [ 5, r ]) ]) {
      const dot = widget.getByRole("button", { name: new RegExp(`^Точка ${col}, ${row}( |$)`) }).locator("span")
      const box = await dot.boundingBox()
      await page.touchscreen.tap(box.x + box.width / 2, box.y + box.height / 2)
      await expect(widget.locator('button[aria-pressed="true"]')).toHaveAccessibleName(new RegExp(`^Точка ${col}, ${row}( |$)`))
      await widget.getByRole("button", { name: "Отначало" }).click()
    }
  })

  test("unit circle at 15°: every peg on the circle", async ({ page }) => {
    const widget = await openWidget(page, "unit_circle", { phone: true })
    for (let angle = 0; angle < 360; angle += 15) {
      const dot = widget.getByRole("button", { name: `${angle} градуса`, exact: true }).locator("span")
      const box = await dot.boundingBox()
      await page.touchscreen.tap(box.x + box.width / 2, box.y + box.height / 2)
      await expect(widget.locator('[data-widget-unit-circle-target="readout"]')).toHaveText(`${angle}°`)
    }
  })

  // With thirteen ticks on a 390px screen the ticks sit 21.8px apart, closer
  // than a 44px button — so each tick's button is one spacing wide, and a tap
  // on a tick's mark must select that tick and not its neighbour.
  test("inequality line with 13 ticks: every tick", async ({ page }) => {
    const widget = await openWidget(page, "inequality_line", { phone: true })
    const ticks = widget.getByRole("button", { name: /^Граница / })
    for (let i = 0; i < await ticks.count(); i += 1) {
      const name = await ticks.nth(i).getAttribute("aria-label")
      const box = await ticks.nth(i).locator("span").first().boundingBox()
      await page.touchscreen.tap(box.x + box.width / 2, box.y + box.height / 2)
      await expect(widget.locator('button[aria-pressed="true"][aria-label^="Граница"]'), `tapped ${name}`).toHaveAttribute("aria-label", name, { timeout: 1000 })
    }
  })

  // In the practice card at 390px a move's label used to get ~31px beside its
  // stepper and ran under the − button; it now wraps to a line of its own.
  test("balance scale: no move's label is covered by its controls", async ({ page }) => {
    const widget = await openWidget(page, "balance_scale", { phone: true })
    const labels = widget.getByText(/^(Махни от двете страни|Махни x от двете страни|Раздели двете страни на)$/)
    await expect(labels).toHaveCount(3)
    for (const label of await labels.all()) {
      const clear = await label.evaluate((element) => {
        const own = element.getBoundingClientRect()
        const covered = [ ...element.parentElement.querySelectorAll("button") ].some((button) => {
          const other = button.getBoundingClientRect()
          return own.left < other.right && other.left < own.right && own.top < other.bottom && other.top < own.bottom
        })
        return element.scrollWidth <= element.clientWidth + 1 && !covered
      })
      expect(clear, await label.textContent()).toBe(true)
    }
  })
})

// equal_parts: a figure with one part highlighted, and every part the
// construction makes equal to it is tapped — on the figure or by its named
// button below. Two problems (see EQUAL_PARTS_PROBLEMS in lib/tasks/e2e.rake):
// OA where two perpendicular bisectors meet (OB and OC to find), and ∠EMA at
// a transversal across two parallels (∠NMB, ∠MNC and ∠FND to find). Each has
// an account per journey: svg, chips, extra, fewer, phone.
test.describe("equal_parts — the parts a construction makes equal", () => {
  const POINTS = {
    segments: { A: [ 13, 82 ], B: [ 90, 79 ], C: [ 49, 19 ], D: [ 51.5, 80.5 ], E: [ 69.5, 49 ], O: [ 50.8, 61.8 ] },
    angles: { A: [ 6, 36 ], B: [ 94, 36 ], C: [ 6, 68 ], D: [ 94, 68 ], M: [ 49, 36 ], N: [ 47.9, 68 ], E: [ 50, 6 ], F: [ 47, 94 ] }
  }

  async function openEqualParts(page, mode, journey) {
    await signIn(page, `widget-equal_parts-${mode}-${journey}@e2e.test`)
    await page.goto("/assignments")
    await page.getByRole("link", { name: "Продължи" }).click()
    await page.waitForURL(/\/questions\/\d+/)
    const widget = page.locator('[data-controller="widget-equal-parts"]')
    await expect(widget.locator("svg")).toBeVisible()
    return widget
  }

  const chip = (widget, name) => widget.getByRole("button", { name, exact: true })
  const chips = (widget) => widget.locator('[data-widget-equal-parts-target="chips"] button')
  const readout = (widget) => widget.locator('[data-widget-equal-parts-target="readout"]')

  // A point on the 100-unit board, in page coordinates — the figure is
  // re-drawn on every toggle, so it is looked up afresh each time.
  async function onPage(widget, [ x, y ]) {
    return widget.locator("svg").evaluate((svg, [ bx, by ]) => {
      const point = svg.createSVGPoint()
      point.x = bx
      point.y = by
      const screen = point.matrixTransform(svg.getScreenCTM())
      return { x: screen.x, y: screen.y }
    }, [ x, y ])
  }

  // Where a finger goes for a part: the middle of a segment, or a point
  // inside an angle's wedge, along its bisector.
  function aim(mode, name) {
    const p = POINTS[mode]
    if (!name.startsWith("∠")) {
      const [ a, b ] = [ p[name[0]], p[name[1]] ]
      return [ (a[0] + b[0]) / 2, (a[1] + b[1]) / 2 ]
    }
    const [ from, vertex, to ] = [ ...name.slice(1) ].map((letter) => p[letter])
    const unit = ([ x, y ]) => { const l = Math.hypot(x, y); return [ x / l, y / l ] }
    const u = unit([ from[0] - vertex[0], from[1] - vertex[1] ])
    const w = unit([ to[0] - vertex[0], to[1] - vertex[1] ])
    const bisector = unit([ u[0] + w[0], u[1] + w[1] ])
    return [ vertex[0] + bisector[0] * 7, vertex[1] + bisector[1] * 7 ]
  }

  async function tapFigure(page, widget, mode, name, { touch = false } = {}) {
    const { x, y } = await onPage(widget, aim(mode, name))
    touch ? await page.touchscreen.tap(x, y) : await page.mouse.click(x, y)
  }

  test("segments: tapping OB and OC on the figure is right, and the ids never reach the page", async ({ page }) => {
    const widget = await openEqualParts(page, "segments", "svg")
    // The ids spell the parts out ("s:OB"); the page only ever sees tokens.
    expect(await widget.evaluate((element) => element.outerHTML)).not.toMatch(/[sa]:[A-Z]{2}/)

    await tapFigure(page, widget, "segments", "OB")
    await expect(chip(widget, "OB")).toHaveAttribute("aria-pressed", "true")
    await tapFigure(page, widget, "segments", "OC")
    await expect(chip(widget, "OC")).toHaveAttribute("aria-pressed", "true")
    // A mis-tap comes off with a second tap on the same segment.
    await tapFigure(page, widget, "segments", "AD")
    await expect(chip(widget, "AD")).toHaveAttribute("aria-pressed", "true")
    await tapFigure(page, widget, "segments", "AD")
    await expect(chip(widget, "AD")).toHaveAttribute("aria-pressed", "false")
    await expect(readout(widget)).toHaveText("Избрани: OB, OC")

    const parts = JSON.parse(await state(page).inputValue()).parts
    expect(parts).toHaveLength(2)
    expect(parts.join()).not.toMatch(/s:/)
    await check(page)
    await expectCorrect(page)
  })

  test("segments: nothing tapped is blank; OB and OC by their buttons is right", async ({ page }) => {
    const widget = await openEqualParts(page, "segments", "chips")
    await expect(readout(widget)).toHaveText("Избрани: още няма")
    await checkRefusedAsBlank(page, "equal_parts")

    // Picked and put back is nothing picked, and as blank as never touching it.
    await chip(widget, "OB").click()
    await chip(widget, "OB").click()
    await expect(state(page)).toHaveValue("")

    await chip(widget, "OB").click()
    await chip(widget, "OC").click()
    await expect(chip(widget, "OB")).toHaveAttribute("aria-pressed", "true")
    await check(page)
    await expectCorrect(page)
  })

  test("segments: one too many is wrong, and the chip names OB, OC", async ({ page }) => {
    const widget = await openEqualParts(page, "segments", "extra")
    for (const name of [ "OB", "OC", "AD" ]) await chip(widget, name).click()
    await check(page)
    await expectWrong(page, { yours: "OB, OC, AD", correct: "OB, OC" })
  })

  test("segments: one too few is wrong, and the chip names OB, OC", async ({ page }) => {
    const widget = await openEqualParts(page, "segments", "fewer")
    await tapFigure(page, widget, "segments", "OB")
    await check(page)
    await expectWrong(page, { yours: "OB", correct: "OB, OC" })
  })

  test("segments: the given OA cannot be picked, on its button or on the figure", async ({ page }) => {
    const widget = await openEqualParts(page, "segments", "phone")
    const given = chip(widget, "OA · дадено")
    await expect(given).toBeDisabled()
    await expect(given).toHaveAttribute("aria-pressed", "false")
    await tapFigure(page, widget, "segments", "OA")
    await expect(readout(widget)).toHaveText("Избрани: още няма")
    await expect(state(page)).toHaveValue("")
    // Only segments are offered: eight of them, the given one included.
    await expect(chips(widget)).toHaveText([ "OA · дадено", "OB", "OC", "AD", "DB", "BE", "EC", "CA" ])
  })

  test("angles: tapping ∠NMB, ∠MNC and ∠FND on the figure is right", async ({ page }) => {
    const widget = await openEqualParts(page, "angles", "svg")
    for (const name of [ "∠NMB", "∠MNC", "∠FND" ]) {
      await tapFigure(page, widget, "angles", name)
      await expect(chip(widget, name)).toHaveAttribute("aria-pressed", "true")
    }
    await expect(readout(widget)).toHaveText("Избрани: ∠NMB, ∠MNC, ∠FND")
    await check(page)
    await expectCorrect(page)
  })

  test("angles: nothing tapped is blank; the three by their buttons is right", async ({ page }) => {
    const widget = await openEqualParts(page, "angles", "chips")
    await checkRefusedAsBlank(page, "equal_parts")
    for (const name of [ "∠FND", "∠MNC", "∠NMB" ]) await chip(widget, name).click()
    await check(page)
    await expectCorrect(page)
  })

  test("angles: one too many is wrong, and the chip names the three", async ({ page }) => {
    const widget = await openEqualParts(page, "angles", "extra")
    for (const name of [ "∠NMB", "∠MNC", "∠FND", "∠BME" ]) await chip(widget, name).click()
    await check(page)
    await expectWrong(page, { yours: "∠NMB, ∠MNC, ∠FND, ∠BME", correct: "∠NMB, ∠MNC, ∠FND" })
  })

  test("angles: one too few is wrong, and the chip names the three", async ({ page }) => {
    const widget = await openEqualParts(page, "angles", "fewer")
    await tapFigure(page, widget, "angles", "∠NMB")
    await tapFigure(page, widget, "angles", "∠MNC")
    await check(page)
    await expectWrong(page, { yours: "∠NMB, ∠MNC", correct: "∠NMB, ∠MNC, ∠FND" })
  })

  test("angles: the lines are drawn but not offered, and the given angle cannot be picked", async ({ page }) => {
    const widget = await openEqualParts(page, "angles", "phone")
    await expect(chips(widget)).toHaveText([ "∠BME", "∠EMA · дадено", "∠AMN", "∠NMB", "∠DNM", "∠MNC", "∠CNF", "∠FND" ])
    for (const name of [ "AB", "CD", "EF" ]) await expect(chip(widget, name)).toHaveCount(0)

    // A tap on a line, well away from every angle, picks nothing.
    for (const point of [ [ 85, 36 ], [ 15, 68 ], [ 49.5, 21 ] ]) {
      const { x, y } = await onPage(widget, point)
      await page.mouse.click(x, y)
    }
    await expect(state(page)).toHaveValue("")

    await expect(chip(widget, "∠EMA · дадено")).toBeDisabled()
    await tapFigure(page, widget, "angles", "∠EMA")
    await expect(readout(widget)).toHaveText("Избрани: още няма")
    await expect(state(page)).toHaveValue("")
  })

  test.describe("at phone width", () => {
    test.use({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true })

    for (const mode of [ "segments", "angles" ]) {
      test(`${mode}: no sideways scroll, every button at least 44px, and a tap on the figure lands`, async ({ page }) => {
        const widget = await openEqualParts(page, mode, "phone")
        const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth)
        expect(overflow).toBeLessThanOrEqual(0)
        const box = await widget.boundingBox()
        expect(box.x).toBeGreaterThanOrEqual(0)
        expect(box.x + box.width).toBeLessThanOrEqual(390)

        for (const button of await chips(widget).all()) {
          const size = await button.boundingBox()
          expect(size.height, await button.textContent()).toBeGreaterThanOrEqual(44)
          expect(size.width, await button.textContent()).toBeGreaterThanOrEqual(44)
          expect(size.x + size.width).toBeLessThanOrEqual(390)
        }

        for (const name of mode === "segments" ? [ "OB", "OC", "AD", "DB", "BE", "EC", "CA" ] : [ "∠BME", "∠AMN", "∠NMB", "∠DNM", "∠MNC", "∠CNF", "∠FND" ]) {
          await tapFigure(page, widget, mode, name, { touch: true })
          await expect(chip(widget, name), `tapped ${name}`).toHaveAttribute("aria-pressed", "true")
          await tapFigure(page, widget, mode, name, { touch: true })
          await expect(chip(widget, name), `tapped ${name} again`).toHaveAttribute("aria-pressed", "false")
        }
      })
    }
  })
})

test("design system: the equal-parts demo runs without console errors", async ({ page }) => {
  const errors = []
  page.on("console", (message) => { if (message.type() === "error") errors.push(message.text()) })
  page.on("pageerror", (error) => errors.push(error.message))

  await page.goto("/design-system")
  const widget = page.locator('[data-controller="widget-equal-parts"]').first()
  await widget.scrollIntoViewIfNeeded()
  await expect(widget.locator("svg line").first()).toBeAttached()
  await expect(widget.getByRole("button", { name: "MA · дадено" })).toBeDisabled()
  await widget.getByRole("button", { name: "MB", exact: true }).click()
  await expect(widget.locator('[data-widget-equal-parts-target="readout"]')).toHaveText("Избрани: MB")
  expect(errors).toEqual([])
})

// An angle that contains two smaller ones at the same vertex (∠ACB holds ∠ACL
// and ∠LCB) used to be buried under them: drawn at one radius, the smaller
// wedges covered it completely and it could only be chosen from the buttons.
// A larger angle now gets a larger radius, so its outer band takes a tap.
test("design system: an angle holding smaller ones can be tapped on its outer band", async ({ page }) => {
  await page.goto("/design-system")
  const widget = page.locator('[data-controller="widget-equal-parts"]').nth(1)
  await widget.scrollIntoViewIfNeeded()
  const svg = widget.locator("svg")
  // A point inside ∠ACB but beyond the two smaller wedges: from C, halfway
  // between the arms, 16 board units out (the inner wedges stop at 9 and 14).
  const point = await svg.evaluate((element) => {
    const C = [46, 10], A = [6, 90], B = [94, 90]
    const unit = ([x, y]) => { const l = Math.hypot(x, y); return [x / l, y / l] }
    const u = unit([A[0] - C[0], A[1] - C[1]]), w = unit([B[0] - C[0], B[1] - C[1]])
    const mid = unit([u[0] + w[0], u[1] + w[1]])
    const p = element.createSVGPoint()
    p.x = C[0] + mid[0] * 16
    p.y = C[1] + mid[1] * 16
    const screen = p.matrixTransform(element.getScreenCTM())
    return { x: screen.x, y: screen.y }
  })
  await page.mouse.click(point.x, point.y)
  await expect(widget.locator('[data-widget-equal-parts-target="readout"]')).toHaveText("Избрани: ∠ACB")
})
