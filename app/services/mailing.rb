# Whether the app can actually put an email in front of a person.
#
# It can when the environment names an SMTP server (SMTP_ADDRESS, with
# SMTP_USERNAME / SMTP_PASSWORD / SMTP_PORT beside it — see
# config/environments/production.rb). The switch reads the environment rather
# than a constant so a deploy without credentials stays exactly as it was:
# every flow whose only step is "we email you a link" is switched off rather
# than left to fail quietly. A confirmation nobody receives keeps a parent from
# linking a child by code (`require_verified_email`); a reset link nobody
# receives is a dead end under the sign-in form that takes the password with
# it; a weekly report nobody receives is a promise in the settings.
#
# The day it first turns on, run `rails mailing:grandfather` once — see there.
module Mailing
  def self.enabled?
    ENV["SMTP_ADDRESS"].present?
  end

  # Sends a mail somebody is waiting for — a reset link, a confirmation, an
  # invitation — now, in the request, rather than through Active Job. Production
  # has no queue backend: `deliver_later` there is a thread in the web process,
  # so a mail queued a moment before a deploy stopped the old release (or before
  # a restart) was simply gone, and one Brevo hiccup failed it with no second
  # try and no trace. Sent here, a failure is at least reported; the page still
  # answers as it would have, because every one of these flows has a „send it
  # again" beside it and none should become an error page over a mail.
  #
  # Mail that merely tells (report activity) stays on `deliver_later`.
  def self.deliver(mail)
    mail.deliver_now
    true
  rescue StandardError => error
    Rails.error.report(error, handled: true)
    false
  end

  # Who mail comes from; MAIL_FROM overrides it for a provider that insists on
  # a particular sender.
  def self.from
    ENV.fetch("MAIL_FROM", "Wunderkind <no-reply@wunderkind.bg>")
  end
end
