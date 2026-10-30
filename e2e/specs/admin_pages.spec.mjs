import { test, expect } from "@playwright/test"
import { signIn } from "../support/helpers.mjs"

// The admin area after the redesign, driven the way it is used: the inbox
// answered, the question browser walked with the keyboard into the editor
// and saved, the topic tree and its views, families down to one child's
// page, and the statistics' ranges. Every page is also checked for console
// errors and, at phone width, for a sideways scroll.
const ADMIN_PAGES = [ "/overseer", "/overseer/inbox", "/overseer/inbox/review", "/overseer/questions",
                      "/overseer/topics", "/overseer/users", "/overseer/stats" ]

// Turbo cancels a fetch still in flight when a navigation overtakes it (a
// link prefetched on hover, a frame still loading) and Chrome logs that as
// an error. It is the framework working, not the page failing.
const BENIGN = [ "The user aborted a request." ]

function collectErrors(page) {
  const errors = []
  page.on("console", (message) => {
    if (message.type() === "error" && !BENIGN.includes(message.text())) errors.push(message.text())
  })
  page.on("pageerror", (error) => { if (!BENIGN.includes(error.message)) errors.push(error.message) })
  return errors
}

test.describe("The admin area", () => {
  test("every page loads without a console error, and none scrolls sideways on a phone", async ({ page }) => {
    const errors = collectErrors(page)
    await signIn(page, "admin@e2e.test")

    for (const path of ADMIN_PAGES) {
      const response = await page.goto(path)
      expect(response.status(), path).toBe(200)
    }

    await page.setViewportSize({ width: 390, height: 844 })
    for (const path of ADMIN_PAGES) {
      await page.goto(path)
      const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth)
      expect(overflow, path).toBeLessThanOrEqual(0)
    }

    expect(errors).toEqual([])
  })

  test("a ticket is answered from the inbox", async ({ page }) => {
    await signIn(page, "admin@e2e.test")
    await page.goto("/overseer/inbox")

    await page.getByRole("region", { name: "Тикети" }).getByRole("link", { name: /Рени/ }).click()
    await page.waitForLoadState("networkidle")
    const ticket = page.getByRole("region", { name: "Тикет" })
    await expect(ticket.getByText("Числата в условието са сбъркани")).toBeVisible()

    await ticket.getByRole("textbox", { name: /Екипът на Wunderkind/ }).fill("Благодарим — гледаме я.")
    await ticket.getByRole("button", { name: "Коментирай" }).click()
    await expect(page.getByText("Благодарим — гледаме я.")).toBeVisible()
  })

  test("the question browser is walked with the keyboard into the editor, and a save is recorded", async ({ page }) => {
    const errors = collectErrors(page)
    await signIn(page, "admin@e2e.test")
    await page.goto("/overseer/questions")

    await page.getByRole("link", { name: /Колко е 40 \+ 2\? \(41\)/ }).click()
    const pane = page.locator("#question-pane")
    await expect(pane).toContainText("Колко е 40 + 2? (41)")
    await expect(pane.getByRole("link", { name: "Редактирай" })).toBeVisible()

    // ↓ moves the selection to the next row, E opens it in the editor.
    await page.keyboard.press("ArrowDown")
    await expect(pane).toContainText("Колко е 40 + 2? (2)")
    await page.keyboard.press("e")
    await page.waitForURL(/\/overseer\/questions\/\d+\/edit/)

    const editUrl = page.url()
    const explanation = page.getByRole("textbox", { name: "Обяснение" })
    await explanation.fill("40 + 2 = 42, защото 40 и още 2 правят 42.")
    await page.getByRole("button", { name: "Запази" }).first().click()
    await page.waitForLoadState("load")

    await page.goto(editUrl)
    await expect(page.getByRole("heading", { name: "История" })).toBeVisible()
    await expect(page.getByText(/Обяснение/).last()).toBeVisible()
    expect(errors).toEqual([])
  })

  test("the topic tree opens a topic beside it and switches views", async ({ page }) => {
    await signIn(page, "admin@e2e.test")
    await page.goto("/overseer/topics")

    await page.getByRole("link", { name: /^Ъгли/ }).click()
    await expect(page.getByRole("link", { name: "Редактирай" })).toBeVisible()

    await page.getByRole("link", { name: "По класове" }).click()
    await expect(page).toHaveURL(/view=grades|grades/)
    await page.getByRole("link", { name: "Карта на предпоставките" }).click()
    await expect(page).toHaveURL(/map/)
  })

  test("families lead to one child's page and its tabs", async ({ page }) => {
    await signIn(page, "admin@e2e.test")
    await page.goto("/overseer/users")

    await page.getByPlaceholder(/Име, прякор/).fill("Ния")
    await page.getByPlaceholder(/Име, прякор/).press("Enter")
    await expect(page.getByText("Ивана").first()).toBeVisible()

    await page.getByRole("link", { name: "Ния", exact: true }).first().click()
    await expect(page.getByRole("heading", { name: "Ния" })).toBeVisible()
    for (const tab of [ "Отговори", "Умения по теми", "Тикети", "Двубои и приятели", "Акаунт", "Обзор" ]) {
      await page.getByRole("link", { name: tab, exact: true }).click()
      await expect(page).toHaveURL(/tab=|users\/\d+$/)
    }

    await page.getByRole("link", { name: "Ивана", exact: true }).first().click()
    await expect(page.getByRole("heading", { name: "Ивана" })).toBeVisible()
  })

  test("statistics switch range", async ({ page }) => {
    await signIn(page, "admin@e2e.test")
    await page.goto("/overseer/stats")

    await page.getByRole("link", { name: "7 дни" }).click()
    await expect(page).toHaveURL(/days=7|range=7/)
    await expect(page.getByText("Активни ученици / седмица")).toBeVisible()
  })
})

test.describe("Two parents of one child", () => {
  test("the second joins by code and can hand the device to the child", async ({ browser }) => {
    const first = await (await browser.newContext()).newPage()
    await signIn(first, "family-a@e2e.test")
    await first.goto("/parents/children")
    await first.getByRole("button", { name: "Покажи код" }).click()
    const label = await first.locator(".family-code").first().getAttribute("aria-label")
    const code = label.match(/([A-Z0-9] ){5}[A-Z0-9]/)[0].replaceAll(" ", "")

    const second = await (await browser.newContext()).newPage()
    await signIn(second, "family-b@e2e.test")
    await second.goto("/parents/children")
    await second.getByRole("textbox", { name: "Код от другия родител" }).fill(code)
    await second.getByRole("button", { name: "Присъедини се" }).click()
    await expect(second.getByRole("link", { name: "Ели" }).first()).toBeVisible()

    await second.getByRole("button", { name: "Влез в профила" }).first().click()
    await second.waitForURL(/home|placements/)
    await expect(second.getByText("В профила на Ели")).toBeVisible()
  })
})
