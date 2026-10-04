import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

test.describe("Viewing the app as another user", () => {
  test("wraps the whole screen in a red frame, refuses writes, and hands back", async ({ page }) => {
    await signIn(page, "admin@e2e.test")

    await page.goto("/overseer/users")
    await page.locator("tr", { hasText: "Стефан" }).getByRole("button", { name: "Прегледай" }).click()
    await page.waitForURL(/calendar/)

    // The frame is a fixed box over the viewport, so it is there whatever the
    // page does and wherever it is scrolled.
    await expect(page.locator(".impersonation-frame")).toBeVisible()
    await expect(page.getByText("Преглеждаш като")).toBeVisible()
    await expect(page.locator(".impersonation-bar")).toContainText("Стефан")

    // The admin area is shut, because from here you are a student — and the
    // landing page bounces anyone signed in to their own home, so a student is
    // put back on the calendar rather than left on it.
    await page.goto("/overseer/questions")
    await expect(page).toHaveURL(/calendar/)
    await expect(page.locator(".impersonation-frame")).toBeVisible()

    // Read-only: a write is refused and says so.
    await page.goto("/profile")
    await expect(page.locator(".impersonation-frame")).toBeVisible()
    await page.getByRole("button", { name: "Запази" }).first().click()
    await expect(page.getByText(/само за четене/i)).toBeVisible()

    await page.getByRole("button", { name: "Спри прегледа" }).click()
    await page.waitForURL(/overseer\/users/)
    await expect(page.locator(".impersonation-frame")).toHaveCount(0)
  })
})
