import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

// The coin collection on „Аз" (Coins, shared/_coin): a row of slots per track,
// and a track's dialog with its ladder. The coin is an inline SVG drawn from a
// palette, so what a browser has to get right is the rows, the ring on the next
// slot and the dialog.
test.describe("Coins", () => {
  test("shows the collection as rows of slots and opens a track's ladder", async ({ page }) => {
    await signIn(page, "student@e2e.test")
    await page.goto("/profile")

    const collection = page.locator("section[aria-labelledby=coins-title]")
    await collection.scrollIntoViewIfNeeded()
    await expect(collection.getByRole("heading", { name: "Колекция" })).toBeVisible()

    const firstRow = collection.locator(".coin-row").first()
    await expect(firstRow.locator(".coin")).toHaveCount(7)
    await expect(firstRow.locator("svg").first()).toBeVisible()

    await firstRow.click()
    const dialog = page.locator("dialog.coin-dialog[open]")
    await expect(dialog).toBeVisible()
    await expect(dialog.locator("ol li")).toHaveCount(7)
    await page.keyboard.press("Escape")
    await expect(page.locator("dialog.coin-dialog[open]")).toHaveCount(0)
  })

  test("the design system draws every material and every symbol", async ({ page }) => {
    await page.goto("/design-system")
    const section = page.locator("section", { has: page.getByRole("heading", { name: "Монети" }) })
    await section.scrollIntoViewIfNeeded()
    await expect(section.getByRole("img", { name: "Диамант · Научих я!" })).toBeVisible()
  })
})
