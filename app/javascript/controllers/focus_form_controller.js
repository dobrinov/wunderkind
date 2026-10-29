import { Controller } from "@hotwired/stimulus"

// The „Какво упражнява" form on a parent's child page: rewrites the preview
// line — what the child will read on their home page — as topics are ticked
// and the reward is typed, so „Запази" is pressed knowing what it will say.
// The sentences come from the page (the locale files), never from here; this
// only fills them in. It also stops a sixth topic being ticked, which the
// server would drop anyway.
//
// Hiding the topic list while „Обща тренировка" is picked is CSS (.focus-form),
// not this: the form has to make sense before the script arrives.
export default class extends Controller {
  static targets = ["mode", "topic", "target", "reward", "preview"]
  static values = { general: String, focus: String, reward: String, empty: String, max: Number }

  connect() {
    this.update()
  }

  update() {
    const checked = this.topicTargets.filter((input) => input.checked)
    this.topicTargets.forEach((input) => { input.disabled = !input.checked && checked.length >= this.maxValue })

    const mode = this.modeTargets.find((input) => input.checked)?.value
    if (mode !== "focus") {
      this.previewTarget.textContent = this.generalValue
      return
    }

    if (checked.length === 0) {
      this.previewTarget.textContent = this.emptyValue
      return
    }

    const lang = document.documentElement.lang || "bg"
    const topics = new Intl.ListFormat(lang, { type: "conjunction" }).format(checked.map((input) => input.dataset.name))
    const target = this.targetTargets.find((input) => input.checked)?.dataset.phrase || ""
    const reward = this.hasRewardTarget ? this.rewardTarget.value.trim() : ""

    let text = this.focusValue.replace("%{topics}", topics).replace("%{target}", target)
    if (reward) text += this.rewardValue.replace("%{reward}", reward)
    this.previewTarget.textContent = text
  }
}
