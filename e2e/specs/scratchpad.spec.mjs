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

    await page.getByRole("button", { name: "Чернова", exact: true }).click()
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

    await page.getByRole("button", { name: "Чернова", exact: true }).click()
    await expect(page.getByText("Смятай тук с пръст или с мишката")).toBeHidden()
  })

  // The second door, under the answer controls, and numbers typed onto the
  // paper rather than drawn.
  test("opens from under the answer and takes a typed note", async ({ page }, testInfo) => {
    await signIn(page, testInfo.project.name === "ipad" ? "note-ipad@e2e.test" : "note@e2e.test")
    await startPractice(page)
    await page.waitForURL(/\/questions\/\d+$/)

    await page.getByRole("button", { name: "Смятай на черновата" }).click()
    const paper = page.locator(".scratchpad canvas")
    await expect(paper).toBeVisible()

    await page.getByRole("button", { name: "Текст — докосни хартията и пиши" }).click()
    const box = await paper.boundingBox()
    await page.mouse.click(box.x + 40, box.y + 60)
    const note = page.getByRole("textbox", { name: "Текст върху черновата" })
    await expect(note).toBeFocused()
    await page.keyboard.type("12 · 4 = 48")
    await page.keyboard.press("Enter")

    await expect(note).toBeHidden()
    await expect(page.getByText("Смятай тук с пръст или с мишката")).toBeHidden()
    const marks = await page.evaluate(() => {
      const key = Object.keys(sessionStorage).find((name) => name.startsWith("scratchpad-"))
      return JSON.parse(sessionStorage.getItem(key))
    })
    expect(marks).toEqual([ expect.objectContaining({ tool: "text", text: "12 · 4 = 48" }) ])
  })
})
