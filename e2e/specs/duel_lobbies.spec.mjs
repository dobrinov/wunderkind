import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

// Choosing who to play and what about.
//
// The part that only a browser can check: the list refreshes itself in a turbo
// frame, and the join button has to break out of that frame or the match
// renders inside the list it was clicked in.
test.describe("the duel lobby browser", () => {
  test("one player opens a room on a topic and the other picks it off the list", async ({ browser }) => {
    const host = await browser.newPage()
    const guest = await browser.newPage()

    await signIn(host, "lobby-a@e2e.test")
    await host.goto("/challenges")

    // Pick a category, then open the room.
    await host.getByText("Избери теми").click()
    await host.getByText("Геометрия", { exact: true }).click()
    await host.getByRole("button", { name: /Намери противник/ }).click()
    await host.waitForURL(/\/challenges\/\d+/)
    await expect(host.getByText(/Търсим противник|Намерен съперник/)).toBeVisible()

    // The other player sees the room, who is in it and what it is about.
    await signIn(guest, "lobby-b@e2e.test")
    await guest.goto("/challenges")

    const row = guest.locator("#open-lobbies li").filter({ hasText: "lora" })
    await expect(row).toBeVisible()
    await expect(row).toContainText("Геометрия")
    await expect(row).toContainText("5 задачи")

    // Joining leaves the frame behind and lands on the match itself.
    await row.getByRole("button", { name: "Влез" }).click()
    await guest.waitForURL(/\/challenges\/\d+/)
    await expect(guest.getByRole("button", { name: "Готов съм" })).toBeVisible()
    // Not rendered inside the list it was clicked in.
    await expect(guest.locator("#open-lobbies")).toHaveCount(0)

    await host.close()
    await guest.close()
  })

  // Deliberately not „the list is empty": other specs leave rooms open and a
  // suite that depends on the order they ran in is a suite that fails for no
  // reason. What has to hold whatever else is waiting is that a student is
  // never offered their own room to join.
  test("never offers a student the room they are sitting in", async ({ page }) => {
    await signIn(page, "skip@e2e.test")
    await page.goto("/challenges")
    await page.getByRole("button", { name: /Намери противник/ }).click()
    await page.waitForURL(/\/challenges\/\d+/)
    const url = page.url()

    await page.goto("/challenges")

    await expect(page.getByText("Кой чака сега")).toBeVisible()
    await expect(page.locator("#open-lobbies li").filter({ hasText: "Скоби" })).toHaveCount(0)

    // Backs out before leaving. A room left open is offered to the next spec's
    // player, who then pairs with a lobby nobody is sitting at — which is a
    // failure in a spec that has nothing to do with this one.
    await page.goto(url)
    await page.getByRole("button", { name: "Откажи" }).click()
    await page.waitForURL(/\/challenges$/)
  })
})
