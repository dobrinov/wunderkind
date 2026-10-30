# Whether the app can actually put an email in front of a person.
#
# It can when the environment names an SMTP server (SMTP_ADDRESS, with
# SMTP_USERNAME / SMTP_PASSWORD / SMTP_PORT beside it — see
# config/environments/production.rb). The switch reads the environment rather
# than a constant so a deploy without credentials stays exactly as it was:
# every flow whose only step is "we email you a link" is switched off rather
# than left to fail quietly. A confirmation nobody receives locks a parent out
# of their own children behind `require_verified_email`; a reset link nobody
# receives is a dead end under the sign-in form that takes the password with
# it; a weekly report nobody receives is a promise in the settings.
#
# The day it first turns on, run `rails mailing:grandfather` once — see there.
module Mailing
  def self.enabled?
    ENV["SMTP_ADDRESS"].present?
  end

  # Who mail comes from; MAIL_FROM overrides it for a provider that insists on
  # a particular sender.
  def self.from
    ENV.fetch("MAIL_FROM", "Wunderkind <no-reply@wunderkind.bg>")
  end

  # Where a reply goes. The sending domain has no mailbox (no MX), so without
  # this a parent answering an email would be writing to nobody — and a real
  # Reply-To is one of the things spam filters look for. MAIL_REPLY_TO in
  # /opt/apps/wunderkind/.env; unset, no header.
  def self.reply_to
    ENV["MAIL_REPLY_TO"].presence
  end
end
