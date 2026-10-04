import { test, expect } from "@playwright/test"
import { signIn, answerQuestion } from "../support/helpers.mjs"
import { QUESTION_COUNT } from "../support/constants.mjs"

// Where a new student is told what they can do.
//
// The one journey in the suite that can only be taken once per account — a
// placed student is never offered it again — so it has an account to itself
// and the suite reseeds between runs.
test.describe("placement", () => {
  test("places a new student and names their level", async ({ page }) => {
    await signIn(page, "placement@e2e.test")

    // Offered on the home page, not buried.
    await expect(page.getByText("Да видим откъде да започнем")).toBeVisible()
    await page.getByRole("link", { name: "Давай!" }).click()

    // The welcome says what is about to happen before it happens.
    await expect(page.getByRole("heading", { name: /Здравей, Пенчо/ })).toBeVisible()
    await page.getByRole("button", { name: "Давай!" }).click()
    await page.waitForURL(/\/questions\/\d+/)

    // The counter says how far through the promised eight you are — not how
    // many have been built, which for a session built one at a time read
    // „1 от 1" on the screen that had just promised eight.
    await expect(page.getByText(`1 от ${QUESTION_COUNT}`)).toBeVisible()

    // Eight questions, one at a time, each chosen from the answers so far.
    const seen = new Set()
    for (let index = 0; index < QUESTION_COUNT; index += 1) {
      seen.add(page.url())
      await answerQuestion(page)
      if (/\/placements\/\d+/.test(page.url())) break
      await page.waitForURL((url) => !seen.has(url.toString()), { timeout: 10000 })
    }

    // And it ends by telling them, in words rather than in a rating.
    await page.waitForURL(/\/placements\/\d+/)
    await expect(page.getByText("Твоето ниво")).toBeVisible()
    await expect(page.getByText(/Отговори вярно на \d+ от 8 задачи/)).toBeVisible()
    // The band leads; a number never does on a student-facing screen.
    await expect(page.getByRole("heading", { name: /Начинаещ|Уверен|Силен|Отличен|Състезател/ })).toBeVisible()

    // Taken once: the card is gone and the home page moves on.
    await page.getByRole("link", { name: "По-късно" }).click()
    await page.waitForURL(/calendar/)
    await expect(page.getByText("Да видим откъде да започнем")).toHaveCount(0)
  })

  test("sends a brand-new sign-up to it", async ({ page }) => {
    const email = `new-${Date.now()}@e2e.test`

    await page.goto("/sign-up")
    await page.getByLabel("Име", { exact: true }).fill("Нова Нина")
    await page.getByLabel("Имейл").fill(email)
    await page.getByLabel("Парола").fill("e2epassword")
    await page.getByRole("button", { name: /Създай|Регистр/ }).click()

    await page.waitForURL(/\/placements\/new/)
    await expect(page.getByRole("heading", { name: /Здравей, Нова/ })).toBeVisible()
  })
})
