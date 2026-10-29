import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

// The problem editor is a textarea with symbol keys and a preview, and the two
// things only a browser can show are that a key lands at the caret (without
// taking the focus away from the text) and that the preview stacks a fraction
// the way the server will store it.
test.describe("Writing a problem", () => {
  test("types a fraction and a symbol, previews them, and stores what the preview showed", async ({ page, browser }) => {
    await signIn(page, "suggest@e2e.test")
    await page.goto("/suggestions/new")

    const text = page.getByLabel("Условие")
    const key = (name) => page.getByRole("toolbar", { name: "Символи" }).getByRole("button", { name, exact: true })
    const preview = page.locator(".plain-editor-preview .question-body")

    // The fraction key before a numerator leaves the bar waiting after the
    // caret; pressed again it steps over it to the denominator.
    await text.click()
    await page.keyboard.type("Колко е ")
    await key("Дроб").click()
    await page.keyboard.type("3")
    await key("Дроб").click()
    await page.keyboard.type("4 от 8")
    await key("На квадрат").click()
    await page.keyboard.type("?")

    await expect(text).toHaveValue("Колко е 3/4 от 8²?")
    await expect(text).toBeFocused()
    await expect(preview.locator(".frac")).toHaveText("34")
    await expect(preview).toContainText("от 8²?")

    // After a digit the key is just the bar.
    await page.keyboard.press("Enter")
    await page.keyboard.type("А 5")
    await key("Дроб").click()
    await page.keyboard.type("6?")
    await expect(preview.locator("p")).toHaveCount(2)
    await expect(preview.locator(".frac")).toHaveCount(2)

    await page.getByLabel("Верен отговор").fill("12")
    await page.getByLabel("Тема").selectOption({ label: "Ъгли" })
    await page.getByRole("button", { name: "Изпрати за преглед" }).click()
    await page.waitForURL(/\/suggestions$/)
    await expect(page.getByText("Колко е 3/4 от 8²?")).toBeVisible()

    // The stored question, as the reviewer sees it: the same stacked fraction.
    const admin = await browser.newContext()
    const adminPage = await admin.newPage()
    await signIn(adminPage, "admin@e2e.test")
    await adminPage.goto("/overseer/reviews")
    const card = adminPage.locator(".question-body", { hasText: "от 8²?" })
    await expect(card.locator(".frac").first()).toHaveText("34")
    await expect(card.locator("p")).toHaveCount(2)
    await admin.close()
  })
})
