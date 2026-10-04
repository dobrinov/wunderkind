import { test, expect } from "@playwright/test"
import { signIn, answerQuestion } from "../support/helpers.mjs"

test.describe("Reviewing your own mistakes", () => {
  test("lists the problem that was got wrong, and practises it without moving the rating", async ({ page }) => {
    await signIn(page, "wrong@e2e.test")

    await page.getByRole("link", { name: /За преговор/ }).click()
    await page.waitForURL(/\/review/)

    await expect(page.getByRole("heading", { name: "За преговор" })).toBeVisible()
    await expect(page.getByText("Упражни грешките си")).toBeVisible()
    await expect(page.locator("li", { hasText: "Колко е 40 + 2?" }).first()).toBeVisible()

    // The two lists are separate: a wrong answer is not a skip.
    await page.getByRole("link", { name: /Не съм го учил/ }).click()
    await expect(page.getByText(/Още не си отбелязвал/)).toBeVisible()

    await page.getByRole("link", { name: /Сгреших/ }).click()
    await page.getByRole("button", { name: "Започни" }).first().click()
    await page.waitForURL(/\/questions\/\d+$/)

    // A mistakes session says so, and refuses the shrug it has already heard.
    await expect(page.locator(".practice-card")).toBeVisible()
    await expect(page.getByRole("button", { name: /Не съм го учил/ })).toBeHidden()

    // The question leaves the list by being answered correctly — which is the
    // whole point of the screen, and the only way off it.
    await answerQuestion(page)
    await page.goto("/review")
    await expect(page.getByText("Нямаш сгрешени задачи. Чисто е!")).toBeVisible()
  })
})
