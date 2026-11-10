# Sends a notification to every device a person turned them on for.
#
# Switched on by environment, like Mailing: VAPID_PUBLIC_KEY and
# VAPID_PRIVATE_KEY (`bin/rails runner 'k = WebPush.generate_key; puts k.public_key, k.private_key'`).
# Without them nothing is offered and nothing is sent, which is what a clone
# and the test suite get. The public key reaches the browser through a meta tag
# in shared/_head; the subject is who a push service writes to about abuse.
#
# A device that has unsubscribed, been reset or uninstalled the app answers 404
# or 410 for good, and its row is deleted then: there is no other way to learn
# that it is gone.
module WebPushDelivery
  SUBJECT = "mailto:hello@wunderkind.bg"

  module_function

  def enabled?
    public_key.present? && private_key.present?
  end

  def public_key = ENV["VAPID_PUBLIC_KEY"]
  def private_key = ENV["VAPID_PRIVATE_KEY"]

  # `url` is opened (or focused) when the notification is tapped; `tag` makes a
  # second notification about the same thing replace the first; `ttl` is how
  # long a push service holds it for a device that is off, which should be no
  # longer than the thing it is about lasts.
  def deliver(user, title:, body:, url:, tag:, ttl:)
    return 0 unless enabled?

    payload = { title: title, body: body, url: url, tag: tag }.to_json
    user.push_subscriptions.to_a.count do |subscription|
      send_one(subscription, payload, ttl)
    end
  end

  def send_one(subscription, payload, ttl)
    WebPush.payload_send(
      message: payload,
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh,
      auth: subscription.auth,
      ttl: ttl.to_i,
      urgency: "high",
      vapid: { subject: SUBJECT, public_key: public_key, private_key: private_key },
      open_timeout: 5,
      read_timeout: 5
    )
    true
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    subscription.destroy
    false
  rescue WebPush::Error, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => error
    Rails.error.report(error, handled: true, context: { push_subscription_id: subscription.id })
    false
  end
end
