import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

test.describe("Goals and rewards", () => {
  test("a parent sets a goal and the child sees it in the parent's own words", async ({ page }) => {
    await signIn(page, "parent@e2e.test")

    await page.getByRole("link", { name: "Виж напредъка" }).first().click()
    await page.waitForURL(/\/parents\/children\/\d+/)
    await expect(page.getByText("Сладолед в събота")).toBeVisible()

    await page.getByRole("link", { name: "Нова цел" }).click()
    await page.getByLabel("Награда").fill("Разходка до зоопарка")
    await page.getByRole("button", { name: "Постави целта" }).click()

    await page.waitForURL(/\/parents\/children\/\d+/)
    await expect(page.getByText("Разходка до зоопарка")).toBeVisible()
    // Two goals now, the fixture's and the one just set: both read as the
    // sentence a parent would say.
    await expect(page.getByText(/поне .* на ден/)).toHaveCount(2)

    // The child reads it on their own home page, verbatim — the half that
    // makes the feature work at all.
    await page.getByRole("button", { name: "Влез в профила" }).click()
    await page.waitForURL(/calendar/)
    await expect(page.getByText("Цели и награди")).toBeVisible()
    await expect(page.getByText("Разходка до зоопарка")).toBeVisible()
  })
})
