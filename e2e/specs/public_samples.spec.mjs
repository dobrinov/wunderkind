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
