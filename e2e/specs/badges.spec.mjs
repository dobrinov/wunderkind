import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

// The medal is CSS — clip-path silhouettes, gradient metals, a masked glyph —
// so whether it renders at all is a question only a browser can answer.
test.describe("Badges", () => {
  test("shows the collection as ladders and opens a medal's detail", async ({ page }) => {
    await signIn(page, "wrong@e2e.test")
    await page.goto("/profile")

    await expect(page.getByRole("heading", { name: "Отличия" })).toBeVisible()

    // A family row, with its rungs as medals.
    const streak = page.locator(".medal-streak").first()
    await expect(streak).toBeVisible()

    // The silhouette is a real clip-path on the struck metal, not a square
    // with a border. It lives on the rim; the wrapper is just a box.
    await expect(streak.locator(".medal-rim")).toHaveCSS("clip-path", /polygon/)

    // A locked medal carries its fill as a custom property, which is how the
    // collection shows distance instead of absence.
    const locked = page.locator(".medal.is-locked").first()
    await expect(locked).toBeVisible()
    expect(await locked.evaluate((el) => el.style.getPropertyValue("--fill"))).toMatch(/%$/)

    // Tapping a medal opens its ladder, and Esc closes it.
    await page.locator("button[data-medal-key-param]").first().click()
    const dialog = page.locator("dialog.medal-dialog[open]")
    await expect(dialog).toBeVisible()
    await expect(dialog.getByText("Стълбата")).toBeVisible()
    await expect(dialog.locator(".medal-l")).toBeVisible()

    await page.getByRole("button", { name: "Готово" }).click()
    await expect(page.locator("dialog.medal-dialog[open]")).toHaveCount(0)
  })

  test("points the home rail at the medal being aimed for", async ({ page }) => {
    await signIn(page, "wrong@e2e.test")

    // What matters is that the rail points at the medal itself rather than a
    // greyed emoji — not where it sits in the DOM.
    await expect(page.getByText("Следващо отличие")).toBeVisible()
    await expect(page.locator(".medal.is-locked").first()).toBeVisible()
  })
})
