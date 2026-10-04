import { test, expect } from "@playwright/test"
import { signIn, answerQuestion, startPractice } from "../support/helpers.mjs"

const counter = (page) => page.locator(".practice-header").getByText(/\d+ от \d+/)

test.describe("Practice", () => {
  test("a student starts a daily session and an answer moves them on", async ({ page }) => {
    await signIn(page, "student@e2e.test")

    await expect(page.getByRole("heading", { name: /Здравей/ })).toBeVisible()
    await startPractice(page)

    await page.waitForURL(/\/questions\/\d+$/)
    await expect(page.locator(".practice-card")).toBeVisible()
    await expect(counter(page)).toContainText("1 от 20")

    // feedback_after_answer is off by default, so a graded answer goes
    // straight on to the next problem. The counter is what says it landed.
    await answerQuestion(page)
    await expect(counter(page)).toContainText("2 от 20")
  })

  test("the feedback card is shown to a student who asked for it", async ({ page }) => {
    await signIn(page, "feedback@e2e.test")
    await startPractice(page)
    await page.waitForURL(/\/questions\/\d+$/)

    await answerQuestion(page)

    await expect(page.locator(".fb-band")).toBeVisible()
    await expect(page.getByText(/Вярно|Грешно/).first()).toBeVisible()
  })

  test("the shrug button is offered and is not a wrong answer", async ({ page }) => {
    await signIn(page, "skip@e2e.test")
    await startPractice(page)
    await page.waitForURL(/\/questions\/\d+$/)

    await page.getByRole("button", { name: "Не съм го учил" }).click()

    // Straight on, with no verdict: a skip is neither right nor wrong.
    await expect(page.locator(".practice-card")).toBeVisible()
    await expect(page.locator(".fb-band")).toHaveCount(0)
  })
})
