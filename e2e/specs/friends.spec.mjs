import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

// Friends, presence and an invitation to a duel.
//
// The invite half needs two browsers: a room opened for one named friend is
// invisible to everybody else, and the only way to prove that is to be
// somebody else and look.
test.describe("friends", () => {
  test("adds a friend by code, and the other one has to say yes", async ({ browser }) => {
    const a = await browser.newPage()
    const c = await browser.newPage()

    await signIn(a, "friend-a@e2e.test")
    await a.goto("/friends")

    // There is no search — a code is the only way in.
    await a.getByPlaceholder("ABC123").fill("firo01")
    await a.getByRole("button", { name: "Добави" }).click()
    await expect(a.getByText(/Изпратихме покана/)).toBeVisible()

    // Until it is accepted, nothing has happened.
    await expect(a.locator("li").filter({ hasText: "firo" })).toHaveCount(0)

    // The request is carried in the nav, so it is not missed.
    await signIn(c, "friend-c@e2e.test")
    await expect(c.getByRole("link", { name: /Приятели \(1\)/ })).toBeVisible()
    await c.goto("/friends")
    await c.getByRole("button", { name: "Приеми" }).click()

    await expect(c.locator("li").filter({ hasText: "fani" })).toBeVisible()

    await a.close()
    await c.close()
  })

  test("sets the format for a friend duel, and the room is played on it", async ({ browser }) => {
    const a = await browser.newContext().then((context) => context.newPage())
    const b = await browser.newContext().then((context) => context.newPage())

    await signIn(a, "friend-a@e2e.test")
    await a.goto("/friends")

    // The choices are a screen of their own, reached from the friend's row.
    await a.locator("li").filter({ hasText: "filip" }).getByRole("link", { name: "На двубой" }).click()
    await a.waitForURL(/\/friends\/\d+\/duel/)
    await expect(a.getByRole("heading", { name: /Двубой с filip/ })).toBeVisible()

    await a.getByText("10 задачи", { exact: true }).click()
    await a.getByText("15 сек.", { exact: true }).click()
    await a.getByRole("button", { name: /Покани filip/ }).click()

    await a.waitForURL(/\/challenges\/\d+/)
    await expect(a.getByText("Чакаме filip")).toBeVisible()
    // The format is the one that was chosen, on the waiting screen's own pills.
    await expect(a.getByText("10 задачи")).toBeVisible()
    await expect(a.getByText(/15 сек/)).toBeVisible()

    // The friend is told what they are accepting before they accept it.
    await signIn(b, "friend-b@e2e.test")
    await b.goto("/challenges")
    const invite = b.locator("li").filter({ hasText: "fani те кани" })
    await expect(invite).toContainText("10 задачи")
    await expect(invite).toContainText("15 сек")
    await invite.getByRole("button", { name: "Приемам!" }).click()

    // And the room really is ten problems long. The bars live on the match
    // scoreboard rather than the ready room, so what the ready room can be
    // asked is what it says the format is.
    await b.waitForURL(/\/challenges\/\d+/)
    await expect(b.getByRole("button", { name: "Готов съм" })).toBeVisible()
    await expect(b.getByText("10 задачи")).toBeVisible()
    await expect(b.getByText(/15 сек/)).toBeVisible()

    // Backs out, so the next spec's pair are not already in a room together.
    await b.getByRole("button", { name: "Откажи" }).click()
    await b.waitForURL(/\/challenges$/)

    await a.close()
    await b.close()
  })

  test("invites a friend to a duel, and nobody else can take the seat", async ({ browser }) => {
    const a = await browser.newContext().then((context) => context.newPage())
    const b = await browser.newContext().then((context) => context.newPage())
    const stranger = await browser.newContext().then((context) => context.newPage())

    await signIn(a, "friend-a@e2e.test")
    await a.goto("/friends")

    // The friend is here, which is the whole reason to invite them now.
    const row = a.locator("li").filter({ hasText: "filip" })
    await expect(row.locator(".presence-dot.is-online")).toBeVisible()
    await row.getByRole("link", { name: "На двубой" }).click()

    // Straight past the format screen on its defaults, which is the fast path.
    await a.waitForURL(/\/friends\/\d+\/duel/)
    await a.getByRole("button", { name: /Покани filip/ }).click()

    // A named wait, not a search.
    await a.waitForURL(/\/challenges\/\d+/)
    await expect(a.getByText("Чакаме filip")).toBeVisible()

    // Invisible to everybody else: not in the public list, and not joinable.
    await signIn(stranger, "skip@e2e.test")
    await stranger.goto("/challenges")
    await expect(stranger.locator("#open-lobbies li").filter({ hasText: "fani" })).toHaveCount(0)
    await expect(stranger.getByText(/те кани на двубой/)).toHaveCount(0)

    // The friend it was sent to sees it and takes it.
    await signIn(b, "friend-b@e2e.test")
    await b.goto("/challenges")
    await expect(b.getByText("fani те кани на двубой")).toBeVisible()
    await b.getByRole("button", { name: "Приемам!" }).click()

    await b.waitForURL(/\/challenges\/\d+/)
    await expect(b.getByRole("button", { name: "Готов съм" })).toBeVisible()

    await a.close()
    await b.close()
    await stranger.close()
  })
})
