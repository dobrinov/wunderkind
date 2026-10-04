export const PASSWORD = "e2epassword"

// Signing in is the first line of nearly every spec, so it is a function and
// not a fixture: a spec that says `await signIn(page, "duel-a@e2e.test")`
// reads as the journey it is testing.
export async function signIn(page, email) {
  await page.goto("/sign-in")
  await page.getByLabel("Имейл").fill(email)
  await page.getByLabel("Парола").fill(PASSWORD)
  await page.getByRole("button", { name: "Вход" }).click()
  await page.waitForURL(/calendar|parents|overseer/)
  await dismissChangelog(page)
}

// The „Какво е новото" dialog opens over whatever you were looking at, for any
// account that is behind on the changelog. Specs that are not about it answer
// it and move on.
export async function dismissChangelog(page) {
  const button = page.getByRole("button", { name: "Разбрах" })
  if (await button.isVisible().catch(() => false)) {
    await button.click()
    await page.waitForLoadState("load")
  }
}

// The hero on the calendar is „Започни" the first time today and „Още една"
// after, so a spec that hard-codes one of them fails the moment another spec
// has already practised as that account.
export function startPractice(page) {
  return page.getByRole("button", { name: /Започни|Още една/ }).first().click()
}

// Answers whatever control the question in front of us happens to use. The
// fixture is all multiple choice (see lib/tasks/e2e.rake), but a helper that
// only knew one input type would turn a fixture change into a suite failure
// with nothing wrong in the app.
export async function answerQuestion(page, { value = "42" } = {}) {
  // Waits for the answer to land on the server and nothing more.
  //
  // Not for a navigation, and not for the URL to change: with
  // feedback_after_answer on, AnswersController#next_path deliberately returns
  // the *same* question's path, because the feedback card is rendered by that
  // page once the question has an answer. And with sound on the form posts by
  // fetch and navigates from JavaScript only after the cue has finished, so
  // there is nothing to join at the moment of the click either.
  //
  // The POST response is the one signal that means the same thing in all four
  // combinations, and it is the one a spec needs: once it is back, the answer
  // is committed and a `goto` cannot race it. Everything after that is a
  // question of what the screen says, which Playwright's retrying expects
  // already handle.
  const submit = async (action) => {
    await Promise.all([
      page.waitForResponse((response) =>
        response.request().method() === "POST" && response.url().includes("/answer")),
      action()
    ])
  }

  const choice = page.locator("button.choice-button").filter({ hasText: value }).first()
  if (await choice.count()) return submit(() => choice.click())

  const typed = page.locator('input[name="value"]:not([type="hidden"])')
  if (await typed.count()) {
    await typed.fill(value)
    return submit(() => page.getByRole("button", { name: "Отговори" }).click())
  }

  // MathLive: a custom element, so the value goes in as real keystrokes.
  await page.locator("math-field").click()
  await page.keyboard.type(value)
  return submit(() => page.getByRole("button", { name: "Отговори" }).click())
}
