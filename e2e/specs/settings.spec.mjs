import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

// Настройки saves a switch the moment it is flipped, by fetch: no save button,
// no reload. What only a browser can show is that the flip reached the server
// — the page says so, and a reload still has it.
test.describe("Settings", () => {
  test("a switch saves itself and is still flipped after a reload", async ({ page }) => {
    await signIn(page, "settings@e2e.test")
    await page.goto("/settings")

    const feedback = page.getByRole("switch", { name: /Обратна връзка след всеки отговор/ })
    await expect(feedback).toBeChecked()
    // The form's own save button is for a browser without JavaScript; with it,
    // there is nothing to press.
    await expect(page.locator("[data-settings-switches-target='fallback']").first()).toBeHidden()

    await feedback.click()
    await expect(page.getByRole("status").filter({ hasText: "Запазено" })).toBeVisible()
    await expect(feedback).not.toBeChecked()

    await page.reload()
    await expect(page.getByRole("switch", { name: /Обратна връзка след всеки отговор/ })).not.toBeChecked()
  })

  test("the daily minutes are one tap", async ({ page }) => {
    await signIn(page, "settings@e2e.test")
    await page.goto("/settings")

    const twenty = page.getByRole("button", { name: "20 минути" })
    await twenty.click()
    await expect(twenty).toHaveAttribute("aria-pressed", "true")
    await expect(page.getByRole("status").filter({ hasText: "Запазено" })).toBeVisible()

    await page.reload()
    await expect(page.getByRole("button", { name: "20 минути" })).toHaveAttribute("aria-pressed", "true")
  })
})

// Sign-up asks „Кой си ти?" first, and the form after it is the one for the
// role picked.
test.describe("Signing up", () => {
  test("a parent picks Родител, signs up and lands on the family page", async ({ page }) => {
    await page.goto("/sign-up")
    await expect(page.getByRole("heading", { name: "Кой си ти?" })).toBeVisible()

    await page.getByRole("link", { name: /Родител/ }).click()
    await expect(page.getByRole("heading", { name: "Профил за родител" })).toBeVisible()

    // The back button returns to the choice rather than leaving sign-up.
    await page.goBack()
    await expect(page.getByRole("heading", { name: "Кой си ти?" })).toBeVisible()
    await page.getByRole("link", { name: /Родител/ }).click()

    await page.getByLabel("Вашето име").fill("Нова Мама")
    await page.getByLabel("Имейл").fill(`parent-${Date.now()}@e2e.test`)
    await page.getByLabel("Парола").fill("e2epassword")
    await page.getByRole("button", { name: "Напред" }).click()

    await page.waitForURL(/\/parents/)
  })
})
