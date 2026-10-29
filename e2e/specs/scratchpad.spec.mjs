import { test, expect } from "@playwright/test"
import { signIn, startPractice, answerQuestion } from "../support/helpers.mjs"

// „Чернова" and the landscape layout: things only a browser can show — a
// canvas that keeps a drawing across the reload to the feedback card, and two
// columns that only exist at a landscape tablet's width.
test.describe("Practising on a landscape tablet", () => {
  test.use({ viewport: { width: 1024, height: 768 } })

  test("keeps the scratch paper across the feedback reload and shows the feedback beside the problem", async ({ page }, testInfo) => {
    await signIn(page, testInfo.project.name === "ipad" ? "feedback-ipad@e2e.test" : "feedback@e2e.test")
    await startPractice(page)
    await page.waitForURL(/\/questions\/\d+$/)

    await page.getByRole("button", { name: "Чернова" }).click()
    const paper = page.locator(".scratchpad canvas")
    await expect(paper).toBeVisible()
    await expect(page.getByText("Смятай тук с пръст или с мишката")).toBeVisible()

    const box = await paper.boundingBox()
    await page.mouse.move(box.x + 60, box.y + 80)
    await page.mouse.down()
    await page.mouse.move(box.x + 200, box.y + 160, { steps: 10 })
    await page.mouse.up()
    await expect(page.getByText("Смятай тук с пръст или с мишката")).toBeHidden()

    await page.getByRole("button", { name: "Скрий черновата" }).click()
    await answerQuestion(page)
    await expect(page.locator(".fb-card")).toBeVisible()

    // Side by side: the feedback starts level with the problem, not under it.
    const card = await page.locator(".practice-card").boundingBox()
    const feedback = await page.locator(".practice-feedback").boundingBox()
    expect(feedback.x).toBeGreaterThan(card.x + card.width - 1)
    expect(Math.abs(feedback.y - card.y)).toBeLessThan(4)

    await page.getByRole("button", { name: "Чернова" }).click()
    await expect(page.getByText("Смятай тук с пръст или с мишката")).toBeHidden()
  })
})
