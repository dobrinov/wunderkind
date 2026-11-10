import { Controller } from "@hotwired/stimulus"
import { appleTouchDevice, consumeInstallPrompt, isInstalled, pendingInstallPrompt } from "../lib/pwa"

// „Wunderkind на началния екран" on „Аз" (profiles/_install). Rendered hidden
// and shown only where installing is possible and has not happened: Chromium
// gets its own install prompt, an iPhone or iPad a dialog with Safari's steps
// (Apple offers no prompt), and every other browser never sees the row.
export default class extends Controller {
  static targets = [ "row", "dialog", "iphone", "ipad" ]

  connect() {
    this.refresh = this.refresh.bind(this)
    document.addEventListener("wk:installable", this.refresh)
    document.addEventListener("wk:installed", this.refresh)
    this.refresh()
  }

  disconnect() {
    document.removeEventListener("wk:installable", this.refresh)
    document.removeEventListener("wk:installed", this.refresh)
  }

  refresh() {
    this.device = appleTouchDevice()
    this.rowTarget.hidden = isInstalled() || !(pendingInstallPrompt() || this.device)
  }

  async open() {
    const prompt = consumeInstallPrompt()
    if (prompt) {
      prompt.prompt()
      const { outcome } = await prompt.userChoice
      if (outcome === "accepted") this.rowTarget.hidden = true
      else this.refresh()
      return
    }
    if (!this.device) return

    this.iphoneTarget.hidden = this.device !== "iphone"
    this.ipadTarget.hidden = this.device !== "ipad"
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }
}
