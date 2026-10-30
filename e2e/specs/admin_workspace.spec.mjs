import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

// An admin who is also a parent: one header with a switch between
// „Семейство" and „Администрация", a dashboard that glances at the family, a
// choice of which side the app opens on, and the child bar leading back to
// the very admin page the device was handed over from.
test.describe("An admin who is also a parent", () => {
  test("moves between the two places and hands the device over from a ticket", async ({ page }) => {
    await signIn(page, "admin-parent@e2e.test")
    await expect(page).toHaveURL(/overseer$/)

    // The dashboard: what waits on the team, and the admin's own child.
    await expect(page.getByRole("heading", { name: /Деян/ })).toBeVisible()
    await expect(page.getByText("от Мая (твоето дете)")).toBeVisible()
    await expect(page.getByRole("link", { name: /Входящи/ }).first()).toBeVisible()

    // Across to the family and back, through the switch.
    await page.locator(".workspace-switch").first().getByRole("link", { name: /Семейство/ }).click()
    await expect(page).toHaveURL(/parents\/children/)
    await expect(page.getByText("Мая").first()).toBeVisible()
    await page.locator(".workspace-switch").first().getByRole("link", { name: /Администрация/ }).click()
    await expect(page).toHaveURL(/overseer/)

    // Open Мая's ticket, hand her the device from it, and come back to it.
    await page.getByText("Колко е 40 + 2?").first().click()
    await expect(page).toHaveURL(/question_reports\/\d+|inbox/)
    const ticketUrl = page.url()
    await page.locator(".child-switcher-toggle").click()
    await page.locator("#child-switcher-menu").getByRole("button", { name: "Мая" }).click()
    await page.waitForURL(/home|placements/)
    await expect(page.getByText("В профила на Мая")).toBeVisible()
    await page.getByRole("button", { name: "Администрация" }).click()
    await expect(page).toHaveURL(ticketUrl)
  })

  test("opens on the side chosen in the account menu", async ({ page }) => {
    await signIn(page, "admin-parent@e2e.test")
    await page.goto("/parents/children")

    // By default the app opens wherever the admin was last.
    await page.locator(".account-button").click()
    await page.getByRole("button", { name: "Изход" }).click()
    await signIn(page, "admin-parent@e2e.test")
    await expect(page).toHaveURL(/parents\/children/)

    await page.locator(".account-button").click()
    await page.getByRole("button", { name: /Винаги „Администрация“/ }).click()
    await expect(page.getByText("Запазено.")).toBeVisible()
    await page.locator(".account-button").click()
    await page.getByRole("button", { name: "Изход" }).click()
    await signIn(page, "admin-parent@e2e.test")
    await expect(page).toHaveURL(/overseer$/)

    // Put it back, so the next run starts from the default.
    await page.locator(".account-button").click()
    await page.getByRole("button", { name: /Последното място/ }).click()
    await expect(page.getByText("Запазено.")).toBeVisible()
  })

  test("gives the switch and the admin menu their own rows on a phone", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 })
    await signIn(page, "admin-parent@e2e.test")
    await page.goto("/overseer")

    const switcher = page.locator(".workspace-switch").last()
    await expect(switcher).toBeVisible()
    await expect(switcher.getByRole("link", { name: /Семейство/ })).toBeVisible()
    await expect(page.locator(".admin-subnav")).toBeVisible()
    const scrollWidth = await page.evaluate(() => document.documentElement.scrollWidth)
    expect(scrollWidth).toBeLessThanOrEqual(390)
  })
})
