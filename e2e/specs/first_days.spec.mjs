import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

// A student who has just been placed: three steps pointing at the page they
// are about to use, then a menu with three places — „Двубой" arrives later,
// when they have some practice behind them (FeatureVisibility).
test.describe("A new student's first days", () => {
  test("gets a three-step tour of „Днес“, once, and a menu without duels", async ({ page }) => {
    await signIn(page, "newbie@e2e.test")

    const bubble = page.locator(".tour-bubble")
    await expect(bubble).toBeVisible()
    await expect(bubble).toContainText("1 / 3")
    await expect(page.locator("[data-tour=hero].tour-highlight")).toBeVisible()

    await bubble.getByRole("button", { name: "Напред" }).click()
    await expect(bubble).toContainText("2 / 3")
    await expect(page.locator("[data-tour=chip].tour-highlight")).toBeVisible()

    await bubble.getByRole("button", { name: "Напред" }).click()
    await expect(bubble).toContainText("3 / 3")

    const finished = page.waitForResponse((response) => response.url().endsWith("/tour") && response.request().method() === "PATCH")
    await bubble.getByRole("button", { name: "Да започваме!" }).click()
    await finished
    await expect(bubble).toHaveCount(0)

    const menu = page.getByRole("navigation", { name: "Главно меню" }).first()
    await expect(menu.getByRole("link", { name: "Упражнения" })).toBeVisible()
    await expect(menu.getByRole("link", { name: /Двубой/ })).toHaveCount(0)

    await page.reload()
    await expect(page.locator(".tour-bubble")).toHaveCount(0)

    // Still findable: a quiet row at the foot of „Аз".
    await menu.getByRole("link", { name: "Аз" }).click()
    await expect(page.getByRole("heading", { name: "Още в Wunderkind" })).toBeVisible()
    await expect(page.getByRole("link", { name: /Двубои/ })).toBeVisible()
  })
})
