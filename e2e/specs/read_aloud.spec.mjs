import { test, expect } from "@playwright/test"
import { signIn, startPractice } from "../support/helpers.mjs"

// „Прочети ми": speechSynthesis is replaced by a recorder, since a headless
// browser has no Bulgarian voice — and whether one exists is the point of the
// first test.
const fakeSpeech = (voices) => {
  window.__spoken = []
  const synth = {
    speaking: false,
    getVoices: () => voices,
    addEventListener() {},
    removeEventListener() {},
    cancel() { this.speaking = false },
    speak(utterance) { this.speaking = true; window.__spoken.push({ text: utterance.text, lang: utterance.lang }) }
  }
  Object.defineProperty(window, "speechSynthesis", { value: synth, configurable: true })
  window.SpeechSynthesisUtterance = function (text) { this.text = text }
}

test.describe("Read aloud", () => {
  test("reads the problem and its options with a Bulgarian voice, and a second press stops", async ({ page }) => {
    await page.addInitScript(fakeSpeech, [ { lang: "bg-BG", name: "Daria" } ])
    await signIn(page, "student@e2e.test")
    await startPractice(page)
    await page.waitForURL(/\/questions\/\d+$/)

    const button = page.getByRole("button", { name: "Прочети ми" })
    await button.click()
    await expect(button).toHaveAttribute("aria-pressed", "true")

    const [ spoken ] = await page.evaluate(() => window.__spoken)
    expect(spoken.lang).toBe("bg-BG")
    const body = (await page.locator(".question-body").innerText()).split(/\s+/)[0]
    expect(spoken.text).toContain(body)

    await button.click()
    await expect(button).toHaveAttribute("aria-pressed", "false")
  })

  test("stays hidden on a device with no Bulgarian voice", async ({ page }) => {
    await page.addInitScript(fakeSpeech, [ { lang: "en-US", name: "Samantha" } ])
    await signIn(page, "student@e2e.test")
    await startPractice(page)
    await page.waitForURL(/\/questions\/\d+$/)

    await expect(page.locator(".practice-card")).toBeVisible()
    await expect(page.getByRole("button", { name: "Прочети ми" })).toBeHidden()
  })
})
