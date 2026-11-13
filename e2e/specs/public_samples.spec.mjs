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

  test("the landing page's pictured answers do not pretend to be buttons", async ({ page }) => {
    await page.goto("/")

    const chips = page.locator(".landing-peek .choice-button")
    await expect(chips.first()).toBeVisible()
    await expect(chips.first()).toHaveCSS("pointer-events", "none")
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
