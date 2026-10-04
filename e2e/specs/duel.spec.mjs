import { test, expect } from "@playwright/test"
import { signIn, answerQuestion } from "../support/helpers.mjs"

// The flow that is worth a browser test more than any other in this app: two
// players, two browsers, one shared clock, and a screen that only moves
// because of what a poll came back with. None of it is observable from a
// request spec.
test.describe("Duels", () => {
  test("two players meet in the ready room and start together", async ({ browser }) => {
    const alice = await browser.newContext()
    const boyan = await browser.newContext()
    const a = await alice.newPage()
    const b = await boyan.newPage()

    try {
      await signIn(a, "duel-a@e2e.test")
      await signIn(b, "duel-b@e2e.test")

      // Alice queues first and waits on an empty lobby.
      await a.getByRole("link", { name: "Търси противник" }).click()
      await a.getByRole("button", { name: /Намери противник/ }).click()
      await a.waitForURL(/\/challenges\/\d+/)
      await expect(a.getByText("Търсим противник…")).toBeVisible()

      // Boyan arrives. The match does not start — both land in the ready room.
      await b.getByRole("link", { name: "Търси противник" }).click()
      await b.getByRole("button", { name: /Намери противник/ }).click()
      await b.waitForURL(/\/challenges\/\d+/)
      await expect(b.getByText("Намерен съперник!")).toBeVisible()

      // Alice's page moves itself on the poll, without her touching anything.
      await expect(a.getByText("Намерен съперник!")).toBeVisible({ timeout: 10_000 })

      // One „Готов съм" is not enough to start anything.
      await a.getByRole("button", { name: "Готов съм" }).click()
      await expect(a.getByText("Чакаме съперника")).toBeVisible()
      await expect(b.locator(".ready-mark.is-ready")).toHaveCount(1, { timeout: 10_000 })

      // The second one starts the countdown, on both screens.
      await b.getByRole("button", { name: "Готов съм" }).click()
      await expect(b.getByText("Започваме!")).toBeVisible()
      await expect(a.getByText("Започваме!")).toBeVisible({ timeout: 10_000 })

      // And the countdown turns into a match for both of them.
      await expect(a.locator(".practice-card")).toBeVisible({ timeout: 20_000 })
      await expect(b.locator(".practice-card")).toBeVisible({ timeout: 20_000 })
      // The shared clock is a draining ring now, and the speed meter beside
      // the problem says what answering this instant would pay.
      await expect(a.locator(".duel-ring")).toBeVisible()
      await expect(a.locator(".speed-meter")).toBeVisible()
      await expect(a.locator(".duel-side-mine .duel-score")).toHaveText("0")

      // A duel has no hint and no shrug — both would be worth points to
      // whoever used them fastest.
      await expect(a.getByRole("button", { name: /Не съм го учил/ })).toHaveCount(0)

      await answerQuestion(a)
      await expect(a.locator(".practice-card")).toBeVisible()
    } finally {
      await alice.close()
      await boyan.close()
    }
  })

  test("a player waiting alone can back out of the lobby", async ({ page }) => {
    await signIn(page, "student@e2e.test")

    await page.getByRole("link", { name: "Търси противник" }).click()
    await page.getByRole("button", { name: /Намери противник/ }).click()
    await page.waitForURL(/\/challenges\/\d+/)

    await page.getByRole("button", { name: "Откажи" }).click()
    await page.waitForURL(/\/challenges$/)
  })
})
