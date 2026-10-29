import { test, expect } from "@playwright/test"
import { signIn, startPractice } from "../support/helpers.mjs"

// The two things a real iPad decides and Chrome does not show: a finger
// drawing on the scratch paper (touch pointer events, no mouse), and a tap on
// an editor symbol key leaving the focus — and so Safari's keyboard — in the
// text box. Runs in WebKit as an iPad with touch only (the „ipad" project).
test.describe("On an iPad", () => {
  test("a finger draws on the scratch paper", async ({ page }) => {
    await signIn(page, "scratch-ipad@e2e.test")
    await startPractice(page)
    await page.waitForURL(/\/questions\/\d+$/)

    await page.getByRole("button", { name: "Чернова" }).tap()
    const paper = page.locator(".scratchpad canvas")
    await expect(paper).toBeVisible()

    // Playwright can tap but not drag a finger, so the stroke is the same
    // sequence of touch pointer events Safari sends, dispatched on the canvas.
    await paper.evaluate((canvas) => {
      const rect = canvas.getBoundingClientRect()
      const fire = (type, x, y) => canvas.dispatchEvent(new PointerEvent(type, {
        pointerId: 7, pointerType: "touch", isPrimary: true, bubbles: true, cancelable: true,
        clientX: rect.left + x, clientY: rect.top + y
      }))
      fire("pointerdown", 40, 60)
      for (let step = 1; step <= 10; step += 1) fire("pointermove", 40 + step * 15, 60 + step * 8)
      fire("pointerup", 190, 140)
    })

    await expect(page.getByText("Смятай тук с пръст или с мишката")).toBeHidden()
    const strokes = await page.evaluate(() => {
      const key = Object.keys(sessionStorage).find((name) => name.startsWith("scratchpad-"))
      return JSON.parse(sessionStorage.getItem(key))
    })
    expect(strokes).toHaveLength(1)
    expect(strokes[0].points.length).toBeGreaterThan(5)

    // The page does not scroll under the finger: the canvas claims the touch.
    expect(await paper.evaluate((canvas) => getComputedStyle(canvas).touchAction)).toBe("none")
  })

  test("a symbol key leaves the focus, and the keyboard, in the text box", async ({ page }) => {
    await signIn(page, "suggest-ipad@e2e.test")
    await page.goto("/suggestions/new")

    const text = page.getByLabel("Условие")
    await text.tap()
    await page.keyboard.type("Колко е 5")
    await page.getByRole("toolbar", { name: "Символи" }).getByRole("button", { name: "На квадрат", exact: true }).tap()

    await expect(text).toBeFocused()
    await expect(text).toHaveValue("Колко е 5²")
    await page.keyboard.type("?")
    await expect(text).toHaveValue("Колко е 5²?")
  })
})
