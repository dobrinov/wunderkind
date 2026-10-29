import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

test.describe("What a child practises", () => {
  test("a parent sets a focus and the child's home shows it", async ({ page }) => {
    await signIn(page, "focus-parent@e2e.test")

    await page.getByRole("link", { name: "Виж напредъка" }).first().click()
    await page.waitForURL(/\/parents\/children\/\d+/)
    await page.locator(".segmented").getByRole("link", { name: "Какво упражнява" }).click()
    await page.waitForURL(/tab=practice/)

    // The topic list is folded away while general practice is picked — CSS,
    // so it has to open when the other card is chosen.
    const topic = page.getByLabel(/Ъгли/)
    await expect(topic).toBeHidden()
    await page.getByText("Фокус върху тема").click()
    await expect(topic).toBeVisible()

    await topic.check()
    await page.getByLabel("Награда (по избор)").fill("кино в събота")
    // The preview is rewritten as the form changes: what Мира will read.
    await expect(page.getByText(/Ралица те помоли да упражняваш Ъгли, докато направиш една стъпка напред\.“ Награда: кино в събота\./)).toBeVisible()

    await page.getByRole("button", { name: "Запази" }).click()
    await page.waitForURL(/tab=practice/)
    await expect(page.getByText("Сега: фокус")).toBeVisible()

    await page.getByRole("button", { name: "Влез в профила" }).click()
    await page.waitForURL(/home/)
    const card = page.locator("#focus-card")
    await expect(card.getByText("Ралица те помоли да упражняваш")).toBeVisible()
    await expect(card.getByText("Ъгли")).toBeVisible()
    await expect(card.getByText("кино в събота")).toBeVisible()
  })
})
