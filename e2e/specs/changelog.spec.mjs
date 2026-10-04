import { test, expect } from "@playwright/test"
import { PASSWORD } from "../support/helpers.mjs"

test.describe("What's new", () => {
  test("greets an account that is behind, once", async ({ page }) => {
    await page.goto("/sign-in")
    await page.getByLabel("Имейл").fill("behind@e2e.test")
    await page.getByLabel("Парола").fill(PASSWORD)
    await page.getByRole("button", { name: "Вход" }).click()
    await page.waitForURL(/calendar/)

    // A real <dialog>, so the page behind it is inert until it is answered.
    const dialog = page.locator("dialog.changelog-dialog")
    await expect(dialog).toBeVisible()
    await expect(dialog.getByText("Какво е новото")).toBeVisible()

    await page.getByRole("button", { name: "Разбрах" }).click()
    await expect(dialog).toBeHidden()

    // And it stays answered across a reload.
    await page.reload()
    await expect(page.locator("dialog.changelog-dialog")).toHaveCount(0)
  })
})
