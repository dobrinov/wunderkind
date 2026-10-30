import { Controller } from "@hotwired/stimulus"

// A mock exam's clock in the practice header: minutes and seconds to the
// deadline the server set (MockExam.deadline). Display only — at zero it
// reloads, and the server, which is the only judge of the time, ends the
// paper and shows the result.
export default class extends Controller {
  static values = { deadline: String }

  connect() {
    this.deadline = Date.parse(this.deadlineValue)
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const left = Math.max(0, Math.round((this.deadline - Date.now()) / 1000))
    const minutes = Math.floor(left / 60)
    const seconds = String(left % 60).padStart(2, "0")
    this.element.textContent = `${minutes}:${seconds}`
    this.element.classList.toggle("text-red-700", left < 60)
    if (left === 0) {
      clearInterval(this.timer)
      window.location.reload()
    }
  }
}
