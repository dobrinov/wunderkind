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

  // Once per deadline. The server is the judge of the time, and a device
  // whose clock runs fast reaches zero while the server still says the paper
  // is running: it renders the same page, which reached zero again and
  // reloaded again, for as long as the clocks disagreed. After the one reload
  // the clock simply rests at 0:00 and the next answer lets the server decide.
  #reloadOnce() {
    const key = `countdown-reloaded:${this.deadlineValue}`
    try {
      if (sessionStorage.getItem(key)) return
      sessionStorage.setItem(key, "1")
    } catch {
      // No storage (private mode): one reload is still better than a stuck clock.
    }
    window.location.reload()
  }

  tick() {
    const left = Math.max(0, Math.round((this.deadline - Date.now()) / 1000))
    const minutes = Math.floor(left / 60)
    const seconds = String(left % 60).padStart(2, "0")
    this.element.textContent = `${minutes}:${seconds}`
    this.element.classList.toggle("text-red-700", left < 60)
    if (left === 0) {
      clearInterval(this.timer)
      this.#reloadOnce()
    }
  }
}
