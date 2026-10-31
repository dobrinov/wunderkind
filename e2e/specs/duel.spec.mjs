import { test, expect } from "@playwright/test"
import { signIn, answerQuestion } from "../support/helpers.mjs"

// „Двубой" in the menu, the way a student gets there: the home page only
// carries a duel card when a friend's invitation is waiting.
const openDuels = (page) =>
  page.getByRole("navigation", { name: "Главно меню" }).first().getByRole("link", { name: /^Двубой/ }).click()

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
      await openDuels(a)
      await a.getByRole("button", { name: /Намери противник/ }).click()
      await a.waitForURL(/\/challenges\/\d+/)
      await expect(a.getByText("Търсим противник…")).toBeVisible()

      // Boyan arrives. The match does not start — both land in the ready room.
      await openDuels(b)
      await b.getByRole("button", { name: /Намери противник/ }).click()
      await b.waitForURL(/\/challenges\/\d+/)
      await expect(b.getByText("Намерен съперник!")).toBeVisible()

      // Alice's page moves itself on the poll, without her touching anything.
      await expect(a.getByText("Намерен съперник!")).toBeVisible({ timeout: 10_000 })

      // One „Давай!" is not enough to start anything.
      await a.getByRole("button", { name: "Давай!" }).click()
      await expect(a.getByText("Чакаме съперника")).toBeVisible()
      await expect(b.locator(".ready-mark.is-ready")).toHaveCount(1, { timeout: 10_000 })

      // The second one starts the countdown, on both screens.
      await b.getByRole("button", { name: "Давай!" }).click()
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

      // On a landscape tablet the whole of a problem is on screen at once:
      // the scoreboard, the speed meter, the problem and every answer, with
      // nothing to scroll to. 1024×700 is an iPad held sideways once
      // Safari's own toolbars have taken their share of the 768. In a duel a
      // scroll is not an inconvenience — it is seconds off the speed bonus.
      await a.setViewportSize({ width: 1024, height: 700 })
      await expect(a.locator(".duel-ring")).toBeInViewport({ ratio: 1 })
      await expect(a.locator(".speed-meter")).toBeInViewport({ ratio: 1 })
      for (const choice of await a.locator("button.choice-button").all()) {
        await expect(choice).toBeInViewport({ ratio: 1 })
      }
      expect(await a.evaluate(() => window.scrollY)).toBe(0)

      // A duel has no hint and no shrug — both would be worth points to
      // whoever used them fastest.
      await expect(a.getByRole("button", { name: /Още не сме го учили/ })).toHaveCount(0)

      await answerQuestion(a)
      await expect(a.locator(".practice-card")).toBeVisible()
    } finally {
      await alice.close()
      await boyan.close()
    }
  })

  // Two children who have just played both want another go. Each used to end
  // up waiting in a room of their own for the other; now the second screen
  // hears about the first press by itself, and the two meet in one room.
  test("a rematch asked for on one screen shows up on the other", async ({ browser }) => {
    const rada = await browser.newContext()
    const rosen = await browser.newContext()
    const a = await rada.newPage()
    const b = await rosen.newPage()

    try {
      await signIn(a, "rematch-a@e2e.test")
      await signIn(b, "rematch-b@e2e.test")
      for (const page of [ a, b ]) {
        await openDuels(page)
        await page.locator("#history a").first().click()
        await expect(page.getByRole("heading", { name: "Равенство" })).toBeVisible()
      }

      await a.getByRole("button", { name: "Реванш" }).click()
      await expect(a.getByText("Чакаме rosen")).toBeVisible()

      // Росен's result screen changes without being touched.
      await expect(b.getByText("rada иска реванш!")).toBeVisible({ timeout: 10_000 })
      await b.getByRole("button", { name: "Приемам реванша" }).click()

      await expect(b.getByText("Намерен съперник!")).toBeVisible()
      await expect(a.getByText("Намерен съперник!")).toBeVisible({ timeout: 10_000 })
      expect(new URL(a.url()).pathname).toBe(new URL(b.url()).pathname)
    } finally {
      await rada.close()
      await rosen.close()
    }
  })

  test("a player waiting alone can back out of the lobby", async ({ page }) => {
    await signIn(page, "student@e2e.test")

    await openDuels(page)
    await page.getByRole("button", { name: /Намери противник/ }).click()
    await page.waitForURL(/\/challenges\/\d+/)

    await page.getByRole("button", { name: "Откажи" }).click()
    await page.waitForURL(/\/challenges$/)
  })
})
