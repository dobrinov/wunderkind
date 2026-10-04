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

  test("invites a friend to a duel, and nobody else can take the seat", async ({ browser }) => {
    const a = await browser.newContext().then((context) => context.newPage())
    const b = await browser.newContext().then((context) => context.newPage())
    const stranger = await browser.newContext().then((context) => context.newPage())

    await signIn(a, "friend-a@e2e.test")
    await a.goto("/friends")

    // The friend is here, which is the whole reason to invite them now.
    const row = a.locator("li").filter({ hasText: "filip" })
    await expect(row.locator(".presence-dot.is-online")).toBeVisible()
    await row.getByRole("button", { name: "На двубой" }).click()

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
