import { Controller } from "@hotwired/stimulus"

// Counts the fields of a form that differ from how the page arrived, shows the
// count in the editor's bar, and asks before a visit or a reload throws them
// away. A field added since (a new option) counts once it holds something.
export default class extends Controller {
  static targets = ["form", "count"]
  static values = { one: String, other: String, confirm: String }

  connect() {
    this.initial = new WeakMap()
    this.fields().forEach((field) => this.initial.set(field, this.valueOf(field)))
    this.submitting = false

    this.beforeVisit = (event) => {
      if (this.dirty() && !this.submitting && !window.confirm(this.confirmValue)) event.preventDefault()
    }
    this.beforeUnload = (event) => {
      if (this.dirty() && !this.submitting) event.preventDefault()
    }
    document.addEventListener("turbo:before-visit", this.beforeVisit)
    window.addEventListener("beforeunload", this.beforeUnload)
    this.refresh()
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.beforeVisit)
    window.removeEventListener("beforeunload", this.beforeUnload)
  }

  submit() {
    this.submitting = true
  }

  refresh() {
    if (!this.hasCountTarget) return
    const count = this.changed()
    const rule = new Intl.PluralRules(document.documentElement.lang || "bg").select(count)
    const template = rule === "one" ? this.oneValue : this.otherValue
    this.countTarget.textContent = template.replace("%{count}", count)
    this.countTarget.hidden = count === 0
  }

  dirty() {
    return this.changed() > 0
  }

  changed() {
    return this.fields().filter((field) => {
      const now = this.valueOf(field)
      return this.initial.has(field) ? this.initial.get(field) !== now : now !== "" && now !== "false"
    }).length
  }

  // A group of radios is one field: switching the answer type is one change,
  // not one unchecked and one checked.
  fields() {
    const radios = new Set()
    return Array.from(this.formTarget.elements).filter((field) => {
      if (!field.name || ["submit", "button"].includes(field.type) || field.name === "authenticity_token") return false
      if (field.type !== "radio") return true
      if (radios.has(field.name)) return false
      radios.add(field.name)
      return true
    })
  }

  valueOf(field) {
    if (field.type === "radio") return this.formTarget.elements.namedItem(field.name).value
    if (field.type === "checkbox") return String(field.checked)
    if (field.type === "file") return field.files.length ? "file" : ""
    return field.value
  }
}
