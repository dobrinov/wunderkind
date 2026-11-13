import { test, expect } from "@playwright/test"

// The worked problems on the public pages (curriculum/_sample). Their options
// are drawn as the app's answer buttons, and visitors arriving from search
// tapped them — when they were inert <li>s, to no effect at all. Public pages:
// no sign-in. The fixture's „Ъгли" (a leaf topic, so it has a page) is all
// „Колко е 40 + 2?" with 42 right and 41 wrong.
test.describe("Worked samples on a public page", () => {
  test("a tapped option says whether it was right and offers more problems", async ({ page }) => {
    const errors = []
    page.on("pageerror", (error) => errors.push(error.message))

    await page.goto("/matematika/tema/agli")
    const sample = page.locator("[data-controller='sample-choice']").first()
    const more = sample.getByRole("link", { name: /Още задачи като тази/ })
    await expect(more).toBeHidden()

    // A wrong pick turns red, and the right one is shown beside it.
    await sample.getByRole("button", { name: "41" }).click()
    await expect(sample.getByRole("button", { name: "41" })).toHaveClass(/is-wrong/)
    await expect(sample.getByRole("button", { name: "42" })).toHaveClass(/is-correct/)
    await expect(more).toBeVisible()
    await expect(more).toHaveAttribute("href", "/sign-up")

    // Then the right one: only it is marked, and nothing is red any more.
    await sample.getByRole("button", { name: "42" }).click()
    await expect(sample.getByRole("button", { name: "42" })).toHaveClass(/is-correct/)
    await expect(sample.getByRole("button", { name: "42" })).toHaveAttribute("aria-pressed", "true")
    await expect(sample.locator(".is-wrong")).toHaveCount(0)

    expect(errors).toEqual([])
  })

  // The hero's problem was a picture of an answered one, and most of the taps
  // it got did nothing. It is a problem to answer now, and leads to the trial.
  test("the landing page's problem can be answered and offers the trial", async ({ page }) => {
    await page.goto("/")

    const card = page.locator(".landing-peek")
    const more = card.getByRole("link", { name: /Още \d+ задачи/ })
    await expect(more).toBeHidden()

    await card.getByRole("button", { name: "12", exact: true }).click()
    await expect(card.getByRole("button", { name: "12", exact: true })).toHaveClass(/is-wrong/)
    await expect(card.getByRole("button", { name: "15", exact: true })).toHaveClass(/is-correct/)
    await expect(card.locator("[data-sample-choice-target='hint']")).toBeHidden()
    await expect(more).toBeVisible()
    await expect(more).toHaveAttribute("href", "/opitay")
  })

  test("a worked solution is folded under its answer and opens on a tap", async ({ page }) => {
    await page.goto("/matematika/tema/agli")

    const fold = page.locator("details.sample-fold").first()
    await expect(fold.locator("p")).toBeHidden()
    await fold.locator("summary").click()
    await expect(fold.locator("p")).toBeVisible()
  })
})

// The public menu (layouts/landingpage, site_nav_controller): a row with
// dropdowns on a laptop, a drawer behind a button on a phone — where the old
// menu was simply hidden.
test.describe("The public menu", () => {
  test("opens one dropdown at a time and closes on a click elsewhere", async ({ page }) => {
    await page.goto("/")
    const menus = page.locator("header details.site-menu")

    await menus.nth(0).locator("summary").click()
    await expect(page.locator("header").getByRole("link", { name: "7. клас" })).toBeVisible()

    await menus.nth(1).locator("summary").click()
    await expect(menus.nth(0)).not.toHaveAttribute("open", "")
    await expect(menus.nth(1)).toHaveAttribute("open", "")

    await page.locator("h1").click()
    await expect(menus.nth(1)).not.toHaveAttribute("open", "")
  })

  test("is a drawer behind a button on a phone", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 })
    await page.goto("/")

    const nav = page.locator("header nav.site-nav")
    const button = page.getByRole("button", { name: "Меню" })
    await expect(nav).toBeHidden()

    await button.click()
    await expect(button).toHaveAttribute("aria-expanded", "true")
    await expect(nav.getByRole("link", { name: "За родители" })).toBeVisible()
    await expect(nav.getByRole("link", { name: /вход/ })).toBeVisible()

    await nav.getByRole("link", { name: "За родители" }).click()
    await expect(page).toHaveURL(/\/za-roditeli$/)
    await expect(page.locator("header nav.site-nav")).toBeHidden()
    expect(await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth)).toBe(0)
  })
})

// The multiplication table (times_tables/_table). The cross of a row and a
// column follows the pointer, with no click; with the answers hidden, pointing
// asks the question and only a tap answers it.
test.describe("The multiplication table", () => {
  test("the cross follows the pointer, and a hidden cell opens only on a tap", async ({ page }) => {
    await page.goto("/matematika/tablitsa-za-umnozhenie")
    const table = page.locator("[data-controller='times-table']")
    const cell = (row, column) => table.locator(`.times-cell[data-row='${row}'][data-column='${column}']`)
    const product = table.locator("[data-times-table-target='product']")
    await expect(product).toHaveText("7 × 8 = 56")

    await cell(6, 4).hover()
    await expect(cell(6, 4)).toHaveClass(/is-on/)
    await expect(cell(6, 9)).toHaveClass(/is-lane/)
    await expect(cell(2, 4)).toHaveClass(/is-lane/)
    await expect(cell(7, 8)).not.toHaveClass(/is-on|is-lane/)
    await expect(product).toHaveText("6 × 4 = 24")
    await expect(table.locator("[data-times-table-target='division']")).toContainText("24 : 4 = 6")

    await table.getByRole("switch").check()
    await cell(3, 9).hover()
    await expect(cell(3, 9)).toHaveClass(/is-on/)
    await expect(cell(3, 9)).toHaveText("?")
    await expect(product).toHaveText("3 × 9 = ?")
    await expect(table.locator("[data-times-table-target='division']")).toHaveText("")

    await cell(3, 9).click()
    await expect(cell(3, 9)).toHaveText("27")
    await expect(product).toHaveText("3 × 9 = 27")

    // Pointing elsewhere moves the cross; what was opened stays open.
    await cell(5, 5).hover()
    await expect(cell(5, 5)).toHaveText("?")
    await expect(cell(3, 9)).toHaveText("27")
  })
})
