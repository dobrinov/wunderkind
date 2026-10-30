import { Controller } from "@hotwired/stimulus"

// The topic editor: the prerequisite picker, the path preview beside it and
// the save bar's count of unsaved changes.
//
// The picker is built on the plain multi-select the server renders, which is
// what is submitted: chips and the search box only select and unselect its
// options. A disabled option (a topic that already requires this one) is
// listed with its reason and cannot be picked — the server refuses the cycle
// again either way.
export default class extends Controller {
  static targets = ["select", "picker", "chips", "search", "suggestions", "count", "pathPrerequisites", "pathEmpty", "pathNote"]
  static values = { one: String, other: String, newNote: String, remove: String, nothing: String }

  connect() {
    this.initial = this.snapshot()
    if (this.hasSelectTarget && this.hasPickerTarget) {
      this.selectTarget.hidden = true
      this.pickerTarget.hidden = false
      this.renderChips()
    }
  }

  get options() {
    return Array.from(this.selectTarget.options)
  }

  // Each field counts once however much of it changed.
  snapshot() {
    const form = document.getElementById("topic_form")
    if (!form) return {}
    const values = {}
    for (const [name, value] of new FormData(form)) {
      if (name === "authenticity_token" || name === "_method") continue
      values[name] = values[name] ? [...values[name], value] : [value]
    }
    return Object.fromEntries(Object.entries(values).map(([name, list]) => [name, list.sort().join(",")]))
  }

  track() {
    if (!this.hasCountTarget) return
    const now = this.snapshot()
    const names = new Set([...Object.keys(now), ...Object.keys(this.initial)])
    const changed = [...names].filter((name) => now[name] !== this.initial[name]).length
    this.countTarget.hidden = changed === 0
    this.countTarget.textContent = (changed === 1 ? this.oneValue : this.otherValue).replace("%{count}", changed)
  }

  filter() {
    const query = this.searchTarget.value.trim().toLowerCase()
    const matches = this.options
      .filter((option) => !option.selected && option.text.toLowerCase().includes(query))
      .slice(0, 8)

    this.suggestionsTarget.replaceChildren(...matches.map((option) => this.suggestion(option)))
    if (matches.length === 0 && query) {
      const empty = document.createElement("p")
      empty.className = "field-hint px-3 py-2"
      empty.textContent = this.nothingValue
      this.suggestionsTarget.append(empty)
    }
  }

  close() {
    this.suggestionsTarget.replaceChildren()
  }

  suggestion(option) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "topic-suggestion"

    const name = document.createElement("span")
    name.textContent = this.nameOf(option)
    const note = document.createElement("span")
    note.className = "topic-suggestion-note"
    note.textContent = option.disabled ? option.dataset.reason : option.parentElement.label
    button.append(name, note)

    if (option.disabled) {
      button.setAttribute("aria-disabled", "true")
    } else {
      button.addEventListener("click", () => this.choose(option, true))
    }
    return button
  }

  // A disabled option carries its reason in its text for the plain select;
  // the picker shows the reason on its own.
  nameOf(option) {
    return option.disabled ? option.text.replace(` — ${option.dataset.reason}`, "") : option.text
  }

  choose(option, selected) {
    option.selected = selected
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.renderChips()
    if (selected) {
      this.searchTarget.value = ""
      this.close()
      this.searchTarget.focus()
    }
  }

  renderChips() {
    const chosen = this.options.filter((option) => option.selected)

    this.chipsTarget.replaceChildren(...chosen.map((option) => {
      const chip = document.createElement("span")
      chip.className = "topic-chip"
      chip.append(this.nameOf(option))
      const remove = document.createElement("button")
      remove.type = "button"
      remove.textContent = "×"
      remove.setAttribute("aria-label", this.removeValue.replace("%{name}", this.nameOf(option)))
      remove.addEventListener("click", () => this.choose(option, false))
      chip.append(remove)
      return chip
    }))

    this.renderPath(chosen)
  }

  // The left column of „Как ще изглежда пътят", with every prerequisite the
  // saved topic does not have yet marked as new.
  renderPath(chosen) {
    if (!this.hasPathPrerequisitesTarget) return

    const nodes = chosen.map((option) => {
      const node = document.createElement("span")
      node.className = option.dataset.saved === "true" ? "topic-node" : "topic-node is-new"
      node.textContent = this.nameOf(option)
      return node
    })
    if (this.hasPathEmptyTarget) this.pathEmptyTarget.hidden = nodes.length > 0
    this.pathPrerequisitesTarget.querySelectorAll(".topic-node").forEach((node) => node.remove())
    this.pathPrerequisitesTarget.prepend(...nodes)

    if (!this.hasPathNoteTarget) return
    const added = chosen.filter((option) => option.dataset.saved !== "true").map((option) => `„${this.nameOf(option)}“`)
    this.pathNoteTarget.hidden = added.length === 0
    this.pathNoteTarget.textContent = this.newNoteValue.replace("%{topics}", added.join(", "))
  }
}
