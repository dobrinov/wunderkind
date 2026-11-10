import { Controller } from "@hotwired/stimulus"
import { appleTouchDevice, isInstalled } from "../lib/pwa"

// „Покани за двубой" (shared/_push_switch): turns duel-invitation
// notifications on or off for this device and the person whose profile is
// open (PushSubscriptionsController, WebPushDelivery).
//
// The browser holds one subscription per device; the server holds which
// people on the device want it. So turning it off removes only this person's
// row and keeps the browser's subscription for a sibling on the same tablet.
//
// The row stays hidden where push cannot work at all. On an iPhone or iPad it
// works only from the home screen, so there the switch is shown disabled with
// a line saying so — the one case where telling beats hiding.
export default class extends Controller {
  static targets = [ "switch", "sub" ]
  static values = { installFirst: String, blocked: String, failed: String, hideWhenOn: Boolean }

  async connect() {
    this.key = document.querySelector("meta[name='vapid-public-key']")?.content
    const supported = this.key && "serviceWorker" in navigator && "PushManager" in window && "Notification" in window

    if (!supported) {
      if (this.key && appleTouchDevice() && !isInstalled()) return this.show({ disabled: true, note: this.installFirstValue })
      return
    }
    if (Notification.permission === "denied") return this.show({ disabled: true, note: this.blockedValue })

    const subscription = await this.currentSubscription()
    const on = subscription ? await this.subscribedHere(subscription) : false
    if (on && this.hideWhenOnValue) return
    this.show({ checked: on })
  }

  async toggle() {
    const wanted = this.switchTarget.checked
    this.switchTarget.disabled = true
    try {
      if (wanted) await this.subscribe()
      else await this.unsubscribe()
    } catch {
      this.switchTarget.checked = !wanted
      if (Notification.permission === "denied") this.note(this.blockedValue)
      else this.note(this.failedValue)
    } finally {
      this.switchTarget.disabled = Notification.permission === "denied"
    }
  }

  async subscribe() {
    // Asked here, inside the tap, because browsers refuse a permission prompt
    // that no gesture asked for.
    const permission = await Notification.requestPermission()
    if (permission !== "granted") throw new Error(permission)

    const registration = await navigator.serviceWorker.ready
    const subscription = (await registration.pushManager.getSubscription()) ||
      await registration.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: this.decodedKey() })
    await this.request("POST", { subscription: subscription.toJSON() })
  }

  async unsubscribe() {
    const subscription = await this.currentSubscription()
    if (subscription) await this.request("DELETE", { endpoint: subscription.endpoint })
  }

  async currentSubscription() {
    const registration = await navigator.serviceWorker.getRegistration("/")
    return registration ? registration.pushManager.getSubscription() : null
  }

  async subscribedHere(subscription) {
    try {
      const response = await fetch(`/push_subscription?endpoint=${encodeURIComponent(subscription.endpoint)}`, {
        headers: { Accept: "application/json" }, credentials: "same-origin"
      })
      return response.ok && (await response.json()).subscribed === true
    } catch {
      return false
    }
  }

  async request(method, body) {
    const response = await fetch("/push_subscription", {
      method,
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
      },
      body: JSON.stringify(body)
    })
    if (!response.ok) throw new Error(String(response.status))
  }

  show({ checked = false, disabled = false, note = null }) {
    this.switchTarget.checked = checked
    this.switchTarget.disabled = disabled
    if (note) this.note(note)
    this.element.hidden = false
  }

  note(text) {
    this.subTarget.textContent = text
  }

  // The VAPID key is URL-safe base64; subscribe() wants the raw bytes.
  decodedKey() {
    const padded = this.key.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(this.key.length / 4) * 4, "=")
    return Uint8Array.from(atob(padded), (char) => char.charCodeAt(0))
  }
}
