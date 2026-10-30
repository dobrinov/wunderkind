import { test, expect } from "@playwright/test"

// The numeric answer field and its keypad (answers/_number_pad), on its
// /design-system demo: what the field draws and what lands in the hidden
// value are both the browser's business, and the demo is the same partial the
// practice and duel screens render. Grading is the server's and is covered by
// RSpec; the value here is exactly the string ExactValue is handed.
test.describe("The number pad", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/design-system")
    await page.locator("#ds-number-pad").scrollIntoViewIfNeeded()
  })

  const pad = (page) => page.locator("#ds-number-pad")
  const value = (page) => pad(page).locator('input[name="value"]')
  const key = (page, name) => pad(page).getByRole("button", { name, exact: true })

  test("builds a stacked fraction from the keys", async ({ page }) => {
    await key(page, "Дроб").click()
    await key(page, "3").click()
    await key(page, "Дроб").click()
    await key(page, "4").click()

    await expect(value(page)).toHaveValue("3/4")
    await expect(pad(page).locator(".number-pad-field .frac")).toHaveText("34")
    await expect(pad(page).locator(".number-pad-field")).toBeFocused()
  })

  test("types a signed decimal from the keyboard and refuses anything else", async ({ page }) => {
    await pad(page).locator(".number-pad-field").click()
    await page.keyboard.type("-0.5 евро")

    await expect(value(page)).toHaveValue("-0,5")
    await expect(pad(page).locator(".number-pad-field")).toContainText("−0,5")

    await page.keyboard.press("Backspace")
    await expect(value(page)).toHaveValue("-0,")
    await key(page, "Минус").click()
    await expect(value(page)).toHaveValue("0,")
  })

  test("stops an empty answer with a word on the field", async ({ page }) => {
    await pad(page).getByRole("button", { name: "Отговори" }).click()
    await expect(pad(page).getByText("Първо напиши отговора си.")).toBeVisible()
    await expect(page).not.toHaveURL(/value=/)

    await key(page, "7").click()
    await expect(pad(page).getByText("Първо напиши отговора си.")).toBeHidden()
  })
})
