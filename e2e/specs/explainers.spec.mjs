import { test, expect } from "@playwright/test"

// The „Обяснено просто" articles (/matematika/obyasneno), each driven the way a
// reader would: the playground's own buttons and sliders, never its internals.
// Public pages — no sign-in, no fixture. The articles' topics are not in the
// e2e bank, so the worked-problem samples are simply absent here; what is
// under test is the article and its playgrounds.
//
// Three things every article is held to, whatever its playgrounds:
//   * it loads with its h1, every playground's controller connects (they are
//     registered lazily — see lib/lazy_controllers.js — so "the markup is
//     there" is not the same as "it works"), and nothing reaches the console;
//   * at phone width the page does not scroll sideways and every control is
//     a 44px target;
//   * each self-check <details> opens onto its answer.
// Then each playground is set to a few positions and the maths it prints is
// checked against the maths, worked out here independently — and each SVG
// figure is checked to stay inside its viewBox at the controls' extremes.
//
// Bugs found while writing this are kept as regression tests at the bottom.

const ARTICLES = {
  "kakvo-e-prosto-chislo": { title: "Какво е просто число?", playgrounds: [ "prime-dots", "sieve" ] },
  "kakvo-e-drob": { title: "Какво е дроб?", playgrounds: [ "pizza", "equal-fractions" ] },
  "obikolka-i-litse": { title: "Обиколка и лице", playgrounds: [ "shape-builder", "fence" ] },
  "okrazhnost-i-pi": { title: "Окръжност и числото π", playgrounds: [ "wheel", "circle-slices" ] },
  "pitagorova-teorema": { title: "Питагоровата теорема", playgrounds: [ "pythagoras-squares", "right-angle-test" ] },
  "kvadratni-uravneniya": { title: "Квадратни уравнения", playgrounds: [ "parabola" ] },
  "kakvo-e-vektor": { title: "Какво е вектор?", playgrounds: [ "vector-sum" ] },
  "kakvo-e-trigonometriya": { title: "Какво е тригонометрия?", playgrounds: [ "unit-triangle", "tree-height" ] }
}

const PHONE = { width: 390, height: 844 }

// The way the articles write a number: decimal comma, a real minus.
const bg = (value, places) => value.toFixed(places).replace(".", ",").replace("-", "−")

// Collects console errors and uncaught exceptions for the life of the page.
function watchErrors(page) {
  const errors = []
  page.on("console", (message) => { if (message.type() === "error") errors.push(`console: ${message.text()}`) })
  page.on("pageerror", (error) => errors.push(`pageerror: ${error.message}`))
  return errors
}

async function openArticle(page, slug) {
  await page.goto(`/matematika/obyasneno/${slug}`)
  await expect(page.locator("h1")).toHaveText(ARTICLES[slug].title)
}

// Something only a connected controller draws: each playground's figure or
// buttons are built in the browser, so their presence is the proof that the
// lazily registered controller loaded and ran. (Stimulus is not on `window`
// here, so the DOM is the only witness.) The sieve's grid is all server
// markup, so it is pressed once instead.
const RENDERED = {
  "prime-dots": '[data-explainer-prime-dots-target="shapes"] button',
  "pizza": '[data-explainer-pizza-target="pie"] path',
  "equal-fractions": '[data-explainer-equal-fractions-target="bar"] span',
  "shape-builder": '[data-explainer-shape-builder-target="figure"] svg polygon',
  "fence": '[data-explainer-fence-target="bars"] li',
  "wheel": '[data-explainer-wheel-target="figure"] circle',
  "circle-slices": '[data-explainer-circle-slices-target="figure"] path',
  "pythagoras-squares": '[data-explainer-pythagoras-squares-target="figure"] polygon',
  "right-angle-test": '[data-explainer-right-angle-test-target="figure"] polygon',
  "parabola": '[data-explainer-parabola-target="figure"] svg path',
  "vector-sum": '[data-explainer-vector-sum-target="figure"] svg polygon',
  "unit-triangle": '[data-explainer-unit-triangle-target="triangle"][points]',
  "tree-height": '[data-explainer-tree-height-target="trunk"][height]'
}

// The playground's root element, once its controller has connected.
async function playground(page, name) {
  const root = page.locator(`[data-controller="explainer-${name}"]`)
  await expect(root).toHaveCount(1)
  if (name === "sieve") {
    // Connected means a press crosses something out; reset leaves it as found.
    await root.getByRole("button", { name: "Задраскай кратните на 2" }).click()
    await expect(root.locator('[data-number="4"]')).toHaveClass(/line-through/)
    await root.getByRole("button", { name: "Отначало" }).click()
    await expect(root.locator('[data-number="4"]')).not.toHaveClass(/line-through/)
  } else {
    await expect(root.locator(RENDERED[name]).first()).toBeAttached()
  }
  return root
}

const target = (root, name, key) => root.locator(`[data-explainer-${name}-target="${key}"]`)

// Drawn elements whose geometry leaves the SVG's viewBox. getBBox is in the
// SVG's own user units (none of these figures uses a transform), so it compares
// directly with the viewBox; stroke width is ignored, half a unit of slack is
// allowed for rounding. A text's box is its whole em box, ascent and descent
// padding included, which no digit or label here fills — so a text is held to
// the middle 70% of its box, roughly where its ink is. `except` names elements that are meant to run past the
// edge and be clipped (the parabola's curve is clamped "just past the board").
async function outsideViewBox(svg, { except = () => false } = {}) {
  return svg.evaluate((element, exceptSource) => {
    const skip = new Function("element", `return (${exceptSource})(element)`)
    const box = element.viewBox.baseVal
    const slack = 0.5
    return [ ...element.querySelectorAll("path, line, circle, polygon, rect, text, ellipse, polyline") ]
      .filter((child) => !skip(child))
      .map((child) => {
        const raw = child.getBBox()
        if (child.tagName !== "text") return { child, b: raw }
        return { child, b: { x: raw.x, y: raw.y + raw.height * 0.15, width: raw.width, height: raw.height * 0.7 } }
      })
      .filter(({ b }) => b.width || b.height)
      .filter(({ b }) => b.x < box.x - slack || b.y < box.y - slack ||
        b.x + b.width > box.x + box.width + slack || b.y + b.height > box.y + box.height + slack)
      .map(({ child, b }) => `${child.tagName}${child.textContent ? ` "${child.textContent}"` : ""} ` +
        `[${b.x.toFixed(1)}, ${b.y.toFixed(1)}, ${(b.x + b.width).toFixed(1)}, ${(b.y + b.height).toFixed(1)}] ` +
        `outside [${box.x}, ${box.y}, ${box.x + box.width}, ${box.y + box.height}]`)
  }, except.toString())
}

async function expectInsideViewBox(svg, options) {
  expect(await outsideViewBox(svg, options)).toEqual([])
}

// ---------------------------------------------------------------------------
// The hub

test("the hub lists all eight articles", async ({ page }) => {
  const errors = watchErrors(page)
  await page.goto("/matematika/obyasneno")
  await expect(page.locator("h1")).toBeVisible()

  for (const [ slug, { title } ] of Object.entries(ARTICLES)) {
    const link = page.locator(`main a[href="/matematika/obyasneno/${slug}"], a[href="/matematika/obyasneno/${slug}"]`).first()
    await expect(link).toContainText(title)
  }
  await expect(page.locator('a.landing-tile[href^="/matematika/obyasneno/"]')).toHaveCount(Object.keys(ARTICLES).length)

  await page.locator(`a.landing-tile[href="/matematika/obyasneno/kakvo-e-drob"]`).click()
  await expect(page.locator("h1")).toHaveText("Какво е дроб?")
  expect(errors).toEqual([])
})

// ---------------------------------------------------------------------------
// Every article: loads, connects, no errors, phone layout, self-check.

for (const [ slug, { title, playgrounds } ] of Object.entries(ARTICLES)) {
  test.describe(`${slug}`, () => {
    test("loads, every playground connects, nothing on the console", async ({ page }) => {
      const errors = watchErrors(page)
      await openArticle(page, slug)

      const roots = page.locator('[data-controller^="explainer-"]')
      await expect(roots).toHaveCount(playgrounds.length)
      for (const name of playgrounds) await playground(page, name)
      await page.waitForLoadState("networkidle")
      expect(errors).toEqual([])
    })

    test("at phone width: no sideways scroll, 44px controls", async ({ page }) => {
      const errors = watchErrors(page)
      await page.setViewportSize(PHONE)
      await openArticle(page, slug)
      for (const name of playgrounds) await playground(page, name)

      const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth)
      expect(overflow, "page scrolls sideways").toBeLessThanOrEqual(0)

      const small = await page.locator(".explainer-play").evaluateAll((cards) => cards.flatMap((card) =>
        [ ...card.querySelectorAll("button, input, summary, select, a") ]
          .filter((control) => control.offsetParent !== null)
          .map((control) => ({ control, box: control.getBoundingClientRect() }))
          .filter(({ box }) => box.height < 44 || box.width < 44)
          .map(({ control, box }) => `${control.tagName} "${control.textContent.trim() || control.getAttribute("aria-label")}" ${box.width.toFixed(0)}×${box.height.toFixed(0)}`)))
      expect(small).toEqual([])

      // Nothing inside a playground is wider than the playground.
      const wide = await page.locator(".explainer-play").evaluateAll((cards) => cards.flatMap((card) => {
        const edge = card.getBoundingClientRect()
        return [ ...card.querySelectorAll("*") ]
          .filter((node) => node.offsetParent !== null || node instanceof SVGElement)
          .filter((node) => !node.closest("svg") || node.tagName === "svg")
          .map((node) => ({ node, box: node.getBoundingClientRect() }))
          .filter(({ box }) => box.right > edge.right + 1 || box.left < edge.left - 1)
          .map(({ node }) => node.tagName + "." + String(node.className?.baseVal ?? node.className).split(" ")[0])
      }))
      expect(wide).toEqual([])
      expect(errors).toEqual([])
    })

    test("each self-check opens onto its answer", async ({ page }) => {
      await openArticle(page, slug)
      const items = page.locator("details")
      const count = await items.count()
      expect(count).toBeGreaterThan(0)
      for (let i = 0; i < count; i++) {
        const item = items.nth(i)
        const answer = item.locator("p")
        await expect(answer).toBeHidden()
        await item.locator("summary").click()
        await expect(item).toHaveAttribute("open", "")
        await expect(answer).toBeVisible()
        expect((await answer.textContent()).trim().length).toBeGreaterThan(0)
      }
    })
  })
}

// ---------------------------------------------------------------------------
// Prime numbers

test.describe("prime_dots", () => {
  test("1 is neither, 12 is composite six ways, 13 is prime one way", async ({ page }) => {
    await openArticle(page, "kakvo-e-prosto-chislo")
    const root = await playground(page, "prime-dots")
    const count = target(root, "prime-dots", "count")
    const verdict = target(root, "prime-dots", "verdict")
    const shapes = target(root, "prime-dots", "shapes").locator("button")
    const dots = target(root, "prime-dots", "dots").locator("span")
    const less = root.getByRole("button", { name: "По-малко точки" })
    const more = root.getByRole("button", { name: "Повече точки" })

    await expect(count).toHaveText("12")
    await expect(verdict).toHaveText("съставно")
    await expect(shapes).toHaveText([ "1 × 12", "2 × 6", "3 × 4", "4 × 3", "6 × 2", "12 × 1" ])
    await expect(dots).toHaveCount(12)
    await expect(target(root, "prime-dots", "note")).toContainText("12 има 6 делителя")

    // A different arrangement redraws the same twelve dots in that shape.
    await shapes.filter({ hasText: "2 × 6" }).click()
    await expect(shapes.filter({ hasText: "2 × 6" })).toHaveAttribute("aria-pressed", "true")
    await expect(target(root, "prime-dots", "dots")).toHaveAttribute("aria-label", "12 точки, подредени в 2 реда по 6")

    await more.click()
    await expect(count).toHaveText("13")
    await expect(verdict).toHaveText("просто")
    await expect(shapes).toHaveText([ "1 × 13", "13 × 1" ])
    await expect(dots).toHaveCount(13)
    await expect(target(root, "prime-dots", "note")).toContainText("само два делителя — 1 и 13")

    for (let i = 0; i < 12; i++) await less.click()
    await expect(count).toHaveText("1")
    await expect(verdict).toHaveText("нито просто, нито съставно")
    await expect(dots).toHaveCount(1)
    // And it stops at 1.
    await less.click()
    await expect(count).toHaveText("1")
  })

  test("every n from 1 to 36 gets the right verdict", async ({ page }) => {
    await openArticle(page, "kakvo-e-prosto-chislo")
    const root = await playground(page, "prime-dots")
    const less = root.getByRole("button", { name: "По-малко точки" })
    const more = root.getByRole("button", { name: "Повече точки" })
    for (let i = 0; i < 11; i++) await less.click()

    const isPrime = (n) => n > 1 && [ ...Array(n).keys() ].slice(2).every((d) => n % d !== 0)
    for (let n = 1; n <= 36; n++) {
      await expect(target(root, "prime-dots", "count")).toHaveText(String(n))
      await expect(target(root, "prime-dots", "verdict")).toHaveText(n === 1 ? "нито просто, нито съставно" : isPrime(n) ? "просто" : "съставно")
      const divisors = [ ...Array(n + 1).keys() ].filter((d) => d > 0 && n % d === 0).length
      await expect(target(root, "prime-dots", "shapes").locator("button")).toHaveCount(divisors)
      if (n < 36) await more.click()
    }
    await more.click()
    await expect(target(root, "prime-dots", "count")).toHaveText("36")
  })
})

test.describe("prime_dots at phone width", () => {
  test("a long row of dots still fits the card: every dot is visible", async ({ page }) => {
    await page.setViewportSize(PHONE)
    await openArticle(page, "kakvo-e-prosto-chislo")
    const root = await playground(page, "prime-dots")
    const more = root.getByRole("button", { name: "Повече точки" })
    const figure = root.locator(".play-figure")
    const fits = () => figure.evaluate((element) => {
      const edge = element.getBoundingClientRect()
      return [ ...element.querySelectorAll("span") ].every((dot) => {
        const box = dot.getBoundingClientRect()
        return box.width >= 4 && box.left >= edge.left - 0.5 && box.right <= edge.right + 0.5
      })
    })

    await more.click() // 13: a prime, one long row
    await expect(target(root, "prime-dots", "dots")).toHaveAttribute("aria-label", "13 точки в една редица")
    expect(await fits()).toBe(true)
    for (let i = 0; i < 23; i++) await more.click()
    await expect(target(root, "prime-dots", "count")).toHaveText("36")
    await target(root, "prime-dots", "shapes").getByRole("button", { name: "1 × 36" }).click()
    await expect(target(root, "prime-dots", "dots").locator("span")).toHaveCount(36)
    expect(await fits()).toBe(true)
    expect(await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth)).toBeLessThanOrEqual(0)
  })
})

test.describe("sieve", () => {
  const PRIMES = [ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97 ]

  test("crossing out 2, 3, 5 and 7 leaves exactly the 25 primes", async ({ page }) => {
    await openArticle(page, "kakvo-e-prosto-chislo")
    const root = await playground(page, "sieve")
    const cells = target(root, "sieve", "cell")
    const standing = () => cells.evaluateAll((all) => all.filter((cell) => !cell.classList.contains("line-through") && cell.dataset.number !== "1").map((cell) => Number(cell.dataset.number)))
    const kept = () => cells.evaluateAll((all) => all.filter((cell) => cell.classList.contains("bg-green-100")).map((cell) => Number(cell.dataset.number)))

    await expect(cells).toHaveCount(100)
    await root.getByRole("button", { name: "Задраскай кратните на 2" }).click()
    // 2 stays, its multiples go.
    expect(await standing()).toEqual([ 2, ...Array.from({ length: 49 }, (_, i) => 2 * i + 3) ])
    expect(await kept()).toEqual([])

    for (const n of [ 3, 5, 7 ]) {
      await root.getByRole("button", { name: `Задраскай кратните на ${n}` }).click()
      await expect(root.getByRole("button", { name: `Задраскай кратните на ${n}` })).toHaveAttribute("aria-pressed", "true")
    }
    expect(await standing()).toEqual(PRIMES)
    expect(await kept()).toEqual(PRIMES)
    await expect(target(root, "sieve", "note")).toContainText("Останаха 25 числа")

    await root.getByRole("button", { name: "Отначало" }).click()
    expect(await kept()).toEqual([])
    expect((await standing()).length).toBe(99)
    await expect(target(root, "sieve", "note")).toContainText("Натисни бутоните поред")
  })
})

// ---------------------------------------------------------------------------
// Fractions

async function fractionOf(locator) {
  return locator.locator(".frac > span").allTextContents()
}

test.describe("pizza", () => {
  test("shows k/d for the slices eaten out of the slices cut", async ({ page }) => {
    await openArticle(page, "kakvo-e-drob")
    const root = await playground(page, "pizza")
    const fraction = target(root, "pizza", "fraction")
    const pie = target(root, "pizza", "pie")
    const keys = target(root, "pizza", "keys").locator("button")
    const fewer = root.getByRole("button", { name: "По-малко парчета" })
    const more = root.getByRole("button", { name: "Повече парчета" })

    await expect(target(root, "pizza", "count")).toHaveText("4")
    await expect.poll(() => fractionOf(fraction)).toEqual([ "3", "4" ])
    await expect(pie.locator("path")).toHaveCount(4)
    await expect(target(root, "pizza", "note")).toHaveText("Изяде 3 от 4 равни парчета. Това са четвъртини.")

    // A numbered button and a slice on the pizza are the same slice.
    await keys.nth(3).click()
    await expect.poll(() => fractionOf(fraction)).toEqual([ "4", "4" ])
    await expect(target(root, "pizza", "note")).toContainText("едно цяло")
    await pie.locator("path").nth(0).click()
    await expect.poll(() => fractionOf(fraction)).toEqual([ "3", "4" ])
    await expect(keys.nth(0)).toHaveAttribute("aria-pressed", "false")

    // Cut finer: the eaten slices keep their places, the bottom changes.
    for (let i = 0; i < 4; i++) await more.click()
    await expect(target(root, "pizza", "count")).toHaveText("8")
    await expect(pie.locator("path")).toHaveCount(8)
    await expect(keys).toHaveCount(8)
    await expect.poll(() => fractionOf(fraction)).toEqual([ "3", "8" ])
    await expect(target(root, "pizza", "note")).toContainText("осмини")

    for (let k = 0; k < 8; k++) if (await keys.nth(k).getAttribute("aria-pressed") === "true") await keys.nth(k).click()
    await expect.poll(() => fractionOf(fraction)).toEqual([ "0", "8" ])
    await expect(target(root, "pizza", "note")).toContainText("Още нищо не си изял.")

    for (let i = 0; i < 10; i++) await more.click()
    await expect(target(root, "pizza", "count")).toHaveText("12")
    for (let i = 0; i < 15; i++) await fewer.click()
    await expect(target(root, "pizza", "count")).toHaveText("1")
    await expect(pie.locator("path")).toHaveCount(1)
    await keys.nth(0).click()
    await expect.poll(() => fractionOf(fraction)).toEqual([ "1", "1" ])
  })

  test("the pizza stays inside its figure at 1 and 12 slices", async ({ page }) => {
    await openArticle(page, "kakvo-e-drob")
    const root = await playground(page, "pizza")
    const pie = target(root, "pizza", "pie")
    await expectInsideViewBox(pie)
    for (let i = 0; i < 8; i++) await root.getByRole("button", { name: "Повече парчета" }).click()
    await expectInsideViewBox(pie)
    for (let i = 0; i < 11; i++) await root.getByRole("button", { name: "По-малко парчета" }).click()
    await expect(pie.locator("path")).toHaveCount(1)
    await expectInsideViewBox(pie)
  })
})

test.describe("equal_fractions", () => {
  test("1/2 = m/2m for every m on the slider", async ({ page }) => {
    await openArticle(page, "kakvo-e-drob")
    const root = await playground(page, "equal-fractions")
    const slider = target(root, "equal-fractions", "slider")
    const bar = target(root, "equal-fractions", "bar")

    await expect.poll(() => fractionOf(target(root, "equal-fractions", "fraction"))).toEqual([ "2", "4" ])
    for (let m = 1; m <= 6; m++) {
      await slider.fill(String(m))
      await expect(target(root, "equal-fractions", "times")).toHaveText(m === 1 ? "1 парче" : `${m} парчета`)
      await expect.poll(() => fractionOf(target(root, "equal-fractions", "fraction"))).toEqual([ String(m), String(2 * m) ])
      await expect(bar.locator("span")).toHaveCount(2 * m)
      await expect(bar.locator("span.bg-primary-400")).toHaveCount(m)
      // The coloured length is half the bar, whatever m is.
      const [ coloured, whole ] = await bar.evaluate((element) => {
        const pieces = [ ...element.children ].filter((piece) => piece.classList.contains("bg-primary-400"))
        const edge = element.getBoundingClientRect()
        return [ pieces.at(-1).getBoundingClientRect().right - edge.left, edge.width ]
      })
      expect(Math.abs(coloured / whole - 0.5)).toBeLessThan(0.03)
    }
  })
})

// ---------------------------------------------------------------------------
// Perimeter and area

test.describe("shape_builder", () => {
  async function setSides(root, a, b) {
    await target(root, "shape-builder", "a").fill(String(a))
    if (b !== undefined) await target(root, "shape-builder", "b").fill(String(b))
  }
  const stat = (root, key) => target(root, "shape-builder", key)

  test("P and S for a rectangle, a square and a right triangle", async ({ page }) => {
    await openArticle(page, "obikolka-i-litse")
    const root = await playground(page, "shape-builder")

    await expect(stat(root, "p")).toHaveText("P = 20 ед.")
    await expect(stat(root, "s")).toHaveText("S = 24 кв. ед.")
    await expect(stat(root, "pFormula")).toHaveText("P = 2 · (6 + 4)")
    await expect(stat(root, "sFormula")).toHaveText("S = 6 · 4")

    await setSides(root, 7, 3)
    await expect(stat(root, "p")).toHaveText("P = 20 ед.")
    await expect(stat(root, "s")).toHaveText("S = 21 кв. ед.")

    await root.getByRole("button", { name: "Квадрат" }).click()
    await setSides(root, 5)
    await expect(target(root, "shape-builder", "bRow")).toBeHidden()
    await expect(stat(root, "p")).toHaveText("P = 20 ед.")
    await expect(stat(root, "s")).toHaveText("S = 25 кв. ед.")
    await expect(stat(root, "pFormula")).toHaveText("P = 4 · 5")

    await root.getByRole("button", { name: "Правоъгълен триъгълник" }).click()
    await setSides(root, 3, 4)
    await expect(target(root, "shape-builder", "aLabel")).toHaveText("Страна a")
    await expect(stat(root, "p")).toHaveText("P = 12 ед.")
    await expect(stat(root, "pFormula")).toHaveText("P = 3 + 4 + 5")
    await expect(stat(root, "s")).toHaveText("S = 6 кв. ед.")
    await expect(stat(root, "sFormula")).toHaveText("S = 3 · 4 : 2")

    await setSides(root, 6, 4)
    // c = √52 ≈ 7,21, P ≈ 17,2; S = 12. A rounded side makes the formula „≈" too.
    await expect(stat(root, "p")).toHaveText(`P ≈ ${bg(6 + 4 + Math.hypot(6, 4), 1)} ед.`)
    await expect(stat(root, "pFormula")).toHaveText(`P ≈ 6 + 4 + ${bg(Math.hypot(6, 4), 1)}`)
    await expect(stat(root, "s")).toHaveText("S = 12 кв. ед.")
    await setSides(root, 5, 3)
    await expect(stat(root, "s")).toHaveText("S = 7,5 кв. ед.")
  })

  test("a parallelogram and a trapezoid use their height for the area", async ({ page }) => {
    await openArticle(page, "obikolka-i-litse")
    const root = await playground(page, "shape-builder")

    await root.getByRole("button", { name: "Успоредник" }).click()
    await setSides(root, 6, 4)
    await expect(stat(root, "s")).toHaveText("S = 24 кв. ед.")
    await expect(stat(root, "p")).toHaveText(`P ≈ ${bg(2 * (6 + Math.hypot(2, 4)), 1)} ед.`)

    await root.getByRole("button", { name: "Трапец" }).click()
    await setSides(root, 8, 3)
    // Top base 8 − 4 = 4, legs √(2² + 3²).
    await expect(stat(root, "s")).toHaveText("S = 18 кв. ед.")
    await expect(stat(root, "sFormula")).toHaveText("S = (8 + 4) · 3 : 2")
    await expect(stat(root, "p")).toHaveText(`P ≈ ${bg(8 + 4 + 2 * Math.hypot(2, 3), 1)} ед.`)

    // A narrow trapezium keeps a top shorter than its bottom: a = 3 → top 1.
    await setSides(root, 3, 2)
    await expect(stat(root, "sFormula")).toHaveText("S = (3 + 1) · 2 : 2")
    await expect(stat(root, "s")).toHaveText("S = 4 кв. ед.")
  })

  test("each shape's slider runs over the range that fits the board", async ({ page }) => {
    await openArticle(page, "obikolka-i-litse")
    const root = await playground(page, "shape-builder")
    const a = target(root, "shape-builder", "a")
    for (const [ shape, min, max ] of [ [ "Правоъгълник", 1, 12 ], [ "Квадрат", 1, 8 ], [ "Правоъгълен триъгълник", 1, 12 ], [ "Успоредник", 1, 11 ], [ "Трапец", 2, 12 ] ]) {
      await root.getByRole("button", { name: shape, exact: true }).click()
      await expect(a).toHaveAttribute("min", String(min))
      await expect(a).toHaveAttribute("max", String(max))
    }
    // A value past the new range is pulled back into it, and the stats follow.
    await root.getByRole("button", { name: "Правоъгълник", exact: true }).click()
    await setSides(root, 12, 4)
    await root.getByRole("button", { name: "Квадрат", exact: true }).click()
    await expect(target(root, "shape-builder", "aOut")).toHaveText("8")
    await expect(stat(root, "s")).toHaveText("S = 64 кв. ед.")
  })

  test("every shape stays on the board at the sliders' extremes", async ({ page }) => {
    await openArticle(page, "obikolka-i-litse")
    const root = await playground(page, "shape-builder")
    const svg = target(root, "shape-builder", "figure").locator("svg")
    for (const shape of [ "Правоъгълник", "Квадрат", "Правоъгълен триъгълник", "Успоредник", "Трапец" ]) {
      await root.getByRole("button", { name: shape, exact: true }).click()
      const a = target(root, "shape-builder", "a")
      const [ min, max ] = [ Number(await a.getAttribute("min")), Number(await a.getAttribute("max")) ]
      for (const [ side, b ] of [ [ min, 1 ], [ max, 8 ], [ max, 1 ], [ min, 8 ] ]) {
        await setSides(root, side, shape === "Квадрат" ? undefined : b)
        await expectInsideViewBox(svg)
      }
    }
  })
})

test.describe("fence", () => {
  test("20 m of fence holds the most at width 5 (25 m²)", async ({ page }) => {
    await openArticle(page, "obikolka-i-litse")
    const root = await playground(page, "fence")
    const width = target(root, "fence", "width")
    const note = target(root, "fence", "note")
    const bars = target(root, "fence", "bars").locator("li")

    await expect(bars).toHaveCount(9)
    for (let w = 1; w <= 9; w++) {
      await expect(bars.nth(w - 1)).toHaveAttribute("aria-label", `Ширина ${w} м — лице ${w * (10 - w)} м²`)
    }

    await width.fill("3")
    await expect(note).toHaveText("Двор 3 на 7 м: оградата е 20 м, тревата е 21 м². Пробвай и други ширини — кога тревата е най-много?")
    await width.fill("5")
    await expect(target(root, "fence", "widthOut")).toHaveText("5 м")
    await expect(note).toContainText("Двор 5 на 5 м: оградата е 20 м, тревата е 25 м².")
    await expect(note).toContainText("квадратът 5 на 5 побира 25 м²")
    // The tallest bar is the 5's, and it is the one highlighted.
    const heights = await bars.evaluateAll((items) => items.map((item) => item.children[1].getBoundingClientRect().height))
    expect(heights.indexOf(Math.max(...heights))).toBe(4)
    await expect(bars.nth(4).locator("span").nth(1)).toHaveClass(/bg-primary-600/)

    // The yard is drawn to one scale both ways.
    await width.fill("2")
    const yard = await target(root, "fence", "yard").boundingBox()
    expect(yard.height / yard.width).toBeCloseTo(8 / 2, 1)
    await width.fill("9")
    await expect(note).toContainText("тревата е 9 м²")
  })
})

// ---------------------------------------------------------------------------
// The circle and π

test.describe("wheel", () => {
  test("one full turn is π · d", async ({ page }) => {
    await openArticle(page, "okrazhnost-i-pi")
    const root = await playground(page, "wheel")
    const roll = target(root, "wheel", "roll")
    const diameter = target(root, "wheel", "diameter")

    await roll.fill("100")
    for (const d of [ 2, 3, 4, 5 ]) {
      await diameter.fill(String(d))
      await expect(target(root, "wheel", "diameterOut")).toHaveText(`${d} см`)
      await expect(target(root, "wheel", "ratio")).toHaveText(`пълен оборот ≈ ${bg(Math.PI * d, 2)} см = π · ${d}`)
      await expect(target(root, "wheel", "rolled")).toHaveText(`изминато: ${bg(Math.PI * d, 1)} см`)
      // Three diameter ticks fit in one turn, never four.
      await expect(target(root, "wheel", "figure").locator("text")).toHaveText([ "1d", "2d", "3d" ])
    }

    await roll.fill("50")
    await diameter.fill("2")
    await expect(target(root, "wheel", "rolled")).toHaveText(`изминато: ${bg(Math.PI, 1)} см`)
    await expect(target(root, "wheel", "ratio")).toHaveText(`диаметри: ${bg(Math.PI / 2, 2)}`)
  })

  test("the wheel stays inside the figure at the end of the roll", async ({ page }) => {
    await openArticle(page, "okrazhnost-i-pi")
    const root = await playground(page, "wheel")
    const svg = target(root, "wheel", "figure")
    await target(root, "wheel", "roll").fill("100")
    for (const d of [ 2, 5 ]) {
      await target(root, "wheel", "diameter").fill(String(d))
      await expectInsideViewBox(svg)
    }
  })
})

test.describe("circle_slices", () => {
  test("draws the number of slices chosen and stays on the board", async ({ page }) => {
    await openArticle(page, "okrazhnost-i-pi")
    const root = await playground(page, "circle-slices")
    const svg = target(root, "circle-slices", "figure")
    const slider = target(root, "circle-slices", "slices")

    await expect(svg.locator("path")).toHaveCount(12)
    for (const n of [ 4, 6, 20, 32 ]) {
      await slider.fill(String(n))
      await expect(target(root, "circle-slices", "slicesOut")).toHaveText(String(n))
      await expect(svg.locator("path")).toHaveCount(n)
      await expect(svg).toHaveAttribute("aria-label", `Кръг, нарязан на ${n} парчета и подреден почти като правоъгълник`)
      await expectInsideViewBox(svg)
    }
    // Each slice is a true sector of r = 70: an up slice stands from the arc's
    // lowest point to its tip, exactly r tall.
    const sector = await svg.locator("path").first().evaluate((element) => element.getBBox().height)
    expect(sector).toBeCloseTo(70, 0)
    // At 32 slices the dashed π·r line is within a few per cent of π · 70.
    // (It spans the whole row, n/2 + ½ chords — see the report.)
    const line = await svg.locator("line").evaluate((element) => element.getBBox().width)
    expect(Math.abs(line / (Math.PI * 70) - 1)).toBeLessThan(0.005)
  })
})

// ---------------------------------------------------------------------------
// Pythagoras

test.describe("pythagoras_squares", () => {
  test("c from the legs: 3, 4 → 5 and 1, 1 → ≈ 1,41", async ({ page }) => {
    await openArticle(page, "pitagorova-teorema")
    const root = await playground(page, "pythagoras-squares")
    const set = async (a, b) => {
      await target(root, "pythagoras-squares", "a").fill(String(a))
      await target(root, "pythagoras-squares", "b").fill(String(b))
    }

    await set(3, 4)
    // „9 + 16 = 25": bare numbers in the row, the names are on the squares.
    await expect(target(root, "pythagoras-squares", "sumA")).toHaveText("9")
    await expect(target(root, "pythagoras-squares", "sumB")).toHaveText("16")
    await expect(target(root, "pythagoras-squares", "sumC")).toHaveText("25")
    await expect(target(root, "pythagoras-squares", "result")).toHaveText("→ c = 5")
    const svg = target(root, "pythagoras-squares", "figure")
    await expect(svg.locator("text")).toHaveText([ "a² = 9", "b² = 16", "c² = 25" ])

    await set(1, 1)
    await expect(target(root, "pythagoras-squares", "sumC")).toHaveText("2")
    await expect(target(root, "pythagoras-squares", "result")).toContainText("1,41")

    await set(6, 8)
    await expect(target(root, "pythagoras-squares", "result")).toHaveText("→ c = 10")
  })

  test("the hypotenuse square is c² big and every square stays on the board", async ({ page }) => {
    await openArticle(page, "pitagorova-teorema")
    const root = await playground(page, "pythagoras-squares")
    const svg = target(root, "pythagoras-squares", "figure")
    for (const [ a, b ] of [ [ 1, 1 ], [ 8, 8 ], [ 8, 1 ], [ 1, 8 ], [ 3, 4 ] ]) {
      await target(root, "pythagoras-squares", "a").fill(String(a))
      await target(root, "pythagoras-squares", "b").fill(String(b))
      await expectInsideViewBox(svg)
      // Area of each drawn square (shoelace) against a², b², a² + b², in 16-px units.
      const areas = await svg.locator("polygon").evaluateAll((polygons) => polygons.slice(0, 3).map((polygon) => {
        const p = [ ...polygon.points ].map(({ x, y }) => [ x, y ])
        return Math.abs(p.reduce((sum, [ x, y ], i) => sum + x * p[(i + 1) % p.length][1] - p[(i + 1) % p.length][0] * y, 0)) / 2 / 256
      }))
      expect(areas[0]).toBeCloseTo(a * a, 1)
      expect(areas[1]).toBeCloseTo(b * b, 1)
      expect(areas[2]).toBeCloseTo(a * a + b * b, 1)
    }
  })
})

test.describe("right_angle_test", () => {
  test("a² + b² = c² at 90° and only at 90°", async ({ page }) => {
    await openArticle(page, "pitagorova-teorema")
    const root = await playground(page, "right-angle-test")
    const slider = target(root, "right-angle-test", "angle")
    const compare = target(root, "right-angle-test", "compare")
    const third = target(root, "right-angle-test", "third")
    const svg = target(root, "right-angle-test", "figure")

    for (let angle = 40; angle <= 140; angle += 5) {
      await slider.fill(String(angle))
      await expect(target(root, "right-angle-test", "angleOut")).toHaveText(`${angle}°`)
      const c2 = 9 + 16 - 2 * 3 * 4 * Math.cos((angle * Math.PI) / 180)
      if (angle === 90) {
        await expect(compare).toHaveText("=")
        await expect(third).toHaveText("c² = 25")
        await expect(target(root, "right-angle-test", "note")).toContainText("Точно 90°")
      } else {
        await expect(compare).toHaveText(angle < 90 ? ">" : "<")
        const rounded = Math.round(c2 * 100) / 100
        await expect(third).toContainText(Number.isInteger(rounded) ? `c² = ${rounded}` : bg(rounded, 2))
        // c² < 25 for an acute angle, > 25 for an obtuse one.
        expect(angle < 90 ? c2 < 25 : c2 > 25).toBe(true)
      }
      // The drawn third side is to scale: 42 px per unit.
      const side = await svg.locator("polygon").evaluate((polygon) => {
        const [ , A, B ] = [ ...polygon.points ]
        return Math.hypot(A.x - B.x, A.y - B.y) / 42
      })
      expect(side).toBeCloseTo(Math.sqrt(c2), 1)
      if (angle === 40 || angle === 140) await expectInsideViewBox(svg)
    }
  })
})

// ---------------------------------------------------------------------------
// Quadratic equations

test.describe("parabola", () => {
  // The a slider runs over positions: −3 … −0,5, then 0,5 … 3.
  const A_POSITIONS = [ -3, -2.5, -2, -1.5, -1, -0.5, 0.5, 1, 1.5, 2, 2.5, 3 ]
  async function set(root, a, b, c) {
    await target(root, "parabola", "a").fill(String(A_POSITIONS.indexOf(a)))
    await target(root, "parabola", "b").fill(String(b))
    await target(root, "parabola", "c").fill(String(c))
  }
  const text = (root, key) => target(root, "parabola", key)
  const curve = (element) => element.tagName === "path"

  test("D and the roots for two, one and no roots", async ({ page }) => {
    await openArticle(page, "kvadratni-uravneniya")
    const root = await playground(page, "parabola")
    const svg = text(root, "figure").locator("svg")

    // The default: x² − x − 6 = 0, D = 25, x = −2 and 3.
    await expect(text(root, "equation")).toHaveText("x² − x − 6 = 0")
    await expect(text(root, "dWork")).toHaveText("D = b² − 4ac = (−1)² − 4 · 1 · (−6) = 25")
    await expect(text(root, "verdict")).toContainText("две решения")
    // x₁ takes the plus, as the formula reads.
    await expect(text(root, "xWork")).toHaveText("x = (−b ± √D) : (2a) = (1 ± 5) : 2, значи x₁ = 3 и x₂ = −2")
    await expect(svg.locator("circle")).toHaveCount(2)
    // Marks are drawn left to right.
    await expect(svg.locator("text")).toHaveText([ "x = −2", "x = 3" ])
    await expect(svg).toHaveAttribute("aria-label", "Парабола на x² − x − 6 = 0: пресича оста x в две точки")

    await set(root, -1, 0, 4)
    await expect(text(root, "equation")).toHaveText("−x² + 4 = 0")
    await expect(text(root, "dWork")).toHaveText("D = b² − 4ac = 0² − 4 · (−1) · 4 = 16")
    // 2a = −2 is bracketed: (0 ± 4) : (−2), x₁ = −2, x₂ = 2.
    await expect(text(root, "xWork")).toHaveText("x = (−b ± √D) : (2a) = (0 ± 4) : (−2), значи x₁ = −2 и x₂ = 2")

    await set(root, 1, 2, 1)
    await expect(text(root, "equation")).toHaveText("x² + 2x + 1 = 0")
    await expect(text(root, "dWork")).toContainText("= 0")
    await expect(text(root, "verdict")).toContainText("едно решение")
    await expect(text(root, "xWork")).toHaveText("x = −b : (2a) = −2 : 2 = −1")
    await expect(svg.locator("circle")).toHaveCount(1)
    await expect(svg).toHaveAttribute("aria-label", "Парабола на x² + 2x + 1 = 0: има една обща точка с оста x")

    await set(root, 2, 1, 3)
    await expect(text(root, "dWork")).toHaveText("D = b² − 4ac = 1² − 4 · 2 · 3 = −23")
    await expect(text(root, "verdict")).toContainText("няма реални решения")
    await expect(svg.locator("circle")).toHaveCount(0)
    await expect(svg).toHaveAttribute("aria-label", "Парабола на 2x² + x + 3 = 0: не стига оста x")

    // 2x² − 5x + 2 = 0: D = 9, x = 0,5 and 2.
    await set(root, 2, -5, 2)
    await expect(text(root, "dWork")).toContainText("= 9")
    await expect(text(root, "xWork")).toContainText("x₁ = 2 и x₂ = 0,5")

    // x² − 3x − 5 = 0: D = 29 is no square, so √29 stays a root and both x round.
    await set(root, 1, -3, -5)
    await expect(text(root, "dWork")).toContainText("= 29")
    await expect(text(root, "xWork")).toHaveText(`x = (−b ± √D) : (2a) = (3 ± √29) : 2, значи x₁ ≈ ${bg((3 + Math.sqrt(29)) / 2, 2)} и x₂ ≈ ${bg((3 - Math.sqrt(29)) / 2, 2)}`)

    // Each root mark sits where the curve crosses the axis: y(x) = 0 there.
    for (const [ a, b, c ] of [ [ 1, -1, -6 ], [ 0.5, 1, -4 ], [ -2, 3, 5 ] ]) {
      await set(root, a, b, c)
      const marks = await svg.locator("circle").evaluateAll((circles) => circles.map((circle) => (Number(circle.getAttribute("cx")) - 260) / 40))
      const D = b * b - 4 * a * c
      const expected = [ (-b - Math.sqrt(D)) / (2 * a), (-b + Math.sqrt(D)) / (2 * a) ].sort((p, q) => p - q)
      // And the curve really is at y = 0 there.
      for (const x of expected) expect(Math.abs(a * x * x + b * x + c)).toBeLessThan(1e-9)
      expect(marks.length).toBe(2)
      marks.forEach((x, i) => expect(x).toBeCloseTo(expected[i], 5))
    }
  })

  test("the a slider steps over 0", async ({ page }) => {
    await openArticle(page, "kvadratni-uravneniya")
    const root = await playground(page, "parabola")
    const seen = []
    for (let i = 0; i <= 11; i++) {
      await text(root, "a").fill(String(i))
      seen.push(await text(root, "aOut").textContent())
    }
    expect(seen).toEqual([ "−3", "−2,5", "−2", "−1,5", "−1", "−0,5", "0,5", "1", "1,5", "2", "2,5", "3" ])
    await text(root, "a").fill("6")
    await text(root, "b").fill("0")
    await text(root, "c").fill("0")
    await expect(text(root, "equation")).toHaveText("0,5x² = 0")
  })

  test("roots and their labels stay on the board", async ({ page }) => {
    await openArticle(page, "kvadratni-uravneniya")
    const root = await playground(page, "parabola")
    const svg = text(root, "figure").locator("svg")
    for (const [ a, b, c ] of [ [ -3, -6, -6 ], [ 3, 6, 6 ], [ 0.5, -6, 6 ], [ -0.5, 6, 6 ], [ 3, -6, -6 ] ]) {
      await set(root, a, b, c)
      await expectInsideViewBox(svg, { except: curve })
    }
  })
})

// ---------------------------------------------------------------------------
// Vectors

test.describe("vector_sum", () => {
  const step = (root, label, direction) => root.getByRole("button", { name: `${label} — с една ${direction === 1 ? "повече" : "по-малко"}` })

  test("the sum and its length", async ({ page }) => {
    await openArticle(page, "kakvo-e-vektor")
    const root = await playground(page, "vector-sum")
    const sum = target(root, "vector-sum", "sum")

    // (4; 2) + (2; 5) = (6; 7), |(6; 7)| = √85.
    await expect(target(root, "vector-sum", "blue")).toHaveText("синият: (4; 2)")
    await expect(sum).toHaveText(`сборът: (6; 7), дължина ≈ ${bg(Math.sqrt(85), 2)}`)

    // (3; 0) + (0; 4) = (3; 4), length exactly 5.
    await step(root, "синият: надясно", -1).click()
    await step(root, "синият: нагоре", -1).click()
    await step(root, "синият: нагоре", -1).click()
    await step(root, "оранжевият: надясно", -1).click()
    await step(root, "оранжевият: надясно", -1).click()
    await step(root, "оранжевият: нагоре", -1).click()
    await expect(target(root, "vector-sum", "orange")).toHaveText("оранжевият: (0; 4)")
    await expect(sum).toHaveText("сборът: (3; 4), дължина 5")

    // Times 2: (6; 0) + (0; 4) = (6; 4); times −1: (−3; 0) + (0; 4) = (−3; 4).
    await target(root, "vector-sum", "multiplier").fill("2")
    await expect(target(root, "vector-sum", "blue")).toHaveText("синият: (6; 0)")
    await expect(sum).toHaveText(`сборът: (6; 4), дължина ≈ ${bg(Math.hypot(6, 4), 2)}`)
    await target(root, "vector-sum", "multiplier").fill("-1")
    await expect(target(root, "vector-sum", "multiplierOut")).toHaveText("−1")
    await expect(target(root, "vector-sum", "blue")).toHaveText("синият: (−3; 0)")
    await expect(sum).toHaveText("сборът: (−3; 4), дължина 5")
    await target(root, "vector-sum", "multiplier").fill("0.5")
    await expect(target(root, "vector-sum", "blue")).toHaveText("синият: (1,5; 0)")

    // The green arrow ends where the orange one does.
    await target(root, "vector-sum", "multiplier").fill("1")
    const tips = await target(root, "vector-sum", "figure").locator("svg polygon").evaluateAll((polygons) =>
      polygons.slice(1).map((polygon) => [ polygon.points[0].x, polygon.points[0].y ]))
    expect(tips[1]).toEqual(tips[2])
    expect(tips[2]).toEqual([ 180 + 3 * 18, 290 - 4 * 18 ])
  })

  test("the arrows stay on the grid at the extremes", async ({ page }) => {
    await openArticle(page, "kakvo-e-vektor")
    const root = await playground(page, "vector-sum")
    const svg = target(root, "vector-sum", "figure").locator("svg")
    const labels = [ "синият: надясно", "синият: нагоре", "оранжевият: надясно", "оранжевият: нагоре" ]

    for (const [ direction, k ] of [ [ 1, "2" ], [ -1, "2" ], [ 1, "-1" ], [ -1, "-1" ] ]) {
      for (const label of labels) for (let i = 0; i < 9; i++) await step(root, label, direction).click()
      await target(root, "vector-sum", "multiplier").fill(k)
      await expectInsideViewBox(svg)
    }
    // Mixed: blue as far one way as it goes, orange the other.
    for (const label of labels.slice(0, 2)) for (let i = 0; i < 9; i++) await step(root, label, -1).click()
    for (const label of labels.slice(2)) for (let i = 0; i < 9; i++) await step(root, label, 1).click()
    await target(root, "vector-sum", "multiplier").fill("-1")
    await expectInsideViewBox(svg)
  })
})

// ---------------------------------------------------------------------------
// Trigonometry

test.describe("unit_triangle", () => {
  test("sin 30° = 0,500, cos 60° = 0,500, tg 45° = 1,000", async ({ page }) => {
    await openArticle(page, "kakvo-e-trigonometriya")
    const root = await playground(page, "unit-triangle")
    const value = (key) => target(root, "unit-triangle", key)

    await root.getByRole("button", { name: "30°" }).click()
    await expect(root.getByRole("button", { name: "30°" })).toHaveAttribute("aria-pressed", "true")
    await expect(value("sinValue")).toHaveText("0,500")
    await expect(value("cosValue")).toHaveText("0,866")
    await expect(value("tanValue")).toHaveText("0,577")
    await expect(value("note")).toContainText("sin 30° е точно 1/2")

    await root.getByRole("button", { name: "60°" }).click()
    await expect(value("cosValue")).toHaveText("0,500")
    await expect(value("sinValue")).toHaveText("0,866")
    await expect(value("degrees")).toHaveText("60°")

    await root.getByRole("button", { name: "45°" }).click()
    await expect(value("tanValue")).toHaveText("1,000")
    await expect(value("sinValue")).toHaveText("0,707")
    await expect(value("cosValue")).toHaveText("0,707")

    // The slider says the same thing, and the drawing is the definition:
    // height and width of a hypotenuse-1 triangle (280 px).
    await value("slider").fill("20")
    await expect(value("sinValue")).toHaveText(bg(Math.sin(Math.PI / 9), 3))
    await expect(root.getByRole("button", { name: "45°" })).toHaveAttribute("aria-pressed", "false")
    const [ height, width ] = await value("sine").evaluate((line) => [
      Number(line.getAttribute("y1")) - Number(line.getAttribute("y2")),
      Number(line.getAttribute("x1")) - 60
    ])
    expect(height / 280).toBeCloseTo(Math.sin(Math.PI / 9), 3)
    expect(width / 280).toBeCloseTo(Math.cos(Math.PI / 9), 3)
  })

  test("the triangle and its labels stay in the figure at 5° and 85°", async ({ page }) => {
    await openArticle(page, "kakvo-e-trigonometriya")
    const root = await playground(page, "unit-triangle")
    for (const degrees of [ "5", "85" ]) {
      await target(root, "unit-triangle", "slider").fill(degrees)
      await expectInsideViewBox(target(root, "unit-triangle", "figure"))
    }
  })
})

test.describe("tree_height", () => {
  test("at 45° the tree is 20,0 m — and 20 · tg α elsewhere", async ({ page }) => {
    await openArticle(page, "kakvo-e-trigonometriya")
    const root = await playground(page, "tree-height")
    const slider = target(root, "tree-height", "slider")
    const formula = target(root, "tree-height", "formula")
    const svg = target(root, "tree-height", "figure")

    await slider.fill("45")
    await expect(formula).toHaveText("Височина = 20 · tg 45° ≈ 20 · 1,000 ≈ 20,0 м")
    for (const degrees of [ 10, 30, 60, 70 ]) {
      await slider.fill(String(degrees))
      const tan = Math.tan((degrees * Math.PI) / 180)
      await expect(formula).toHaveText(`Височина = 20 · tg ${degrees}° ≈ 20 · ${bg(tan, 3)} ≈ ${bg(20 * tan, 1)} м`)
      // The numbers shown multiply to the height shown.
      expect(bg(20 * Number(tan.toFixed(3)), 1)).toBe(bg(20 * tan, 1))
      // The line of sight makes the real angle with the ground.
      const drawn = await target(root, "tree-height", "sight").evaluate((line) =>
        Math.atan2(Number(line.getAttribute("y1")) - Number(line.getAttribute("y2")), Number(line.getAttribute("x2")) - Number(line.getAttribute("x1"))) * 180 / Math.PI)
      expect(drawn).toBeCloseTo(degrees, 5)
      if (degrees === 10 || degrees === 70) await expectInsideViewBox(svg)
    }
  })
})

// ---------------------------------------------------------------------------
// Regressions: bugs found while writing this suite, kept so they stay fixed.

test.describe("regressions", () => {
  test("wheel: at the start of the roll the wheel stays inside the figure", async ({ page }) => {
    await openArticle(page, "okrazhnost-i-pi")
    const root = await playground(page, "wheel")
    await target(root, "wheel", "roll").fill("0")
    for (const d of [ 2, 5 ]) {
      await target(root, "wheel", "diameter").fill(String(d))
      await expectInsideViewBox(target(root, "wheel", "figure"))
    }
  })

  test("pythagoras_squares: a rounded c reads „c ≈ 1,41“, not „c = ≈ 1,41“", async ({ page }) => {
    await openArticle(page, "pitagorova-teorema")
    const root = await playground(page, "pythagoras-squares")
    await target(root, "pythagoras-squares", "a").fill("1")
    await target(root, "pythagoras-squares", "b").fill("1")
    await expect(target(root, "pythagoras-squares", "result")).toHaveText("→ c ≈ 1,41", { timeout: 2_000 })
  })

  test("right_angle_test: a rounded c² reads „c² ≈ …“, not „c² = ≈ …“", async ({ page }) => {
    await openArticle(page, "pitagorova-teorema")
    const root = await playground(page, "right-angle-test")
    await target(root, "right-angle-test", "angle").fill("40")
    await expect(target(root, "right-angle-test", "third")).toHaveText(`c² ≈ ${bg(25 - 24 * Math.cos((40 * Math.PI) / 180), 2)}`, { timeout: 2_000 })
  })
})
