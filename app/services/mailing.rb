# Whether the app can actually put an email in front of a person.
#
# No delivery is configured yet, so every flow whose only step is "we email
# you a link" is switched off here rather than left to fail quietly. A
# confirmation nobody receives locks a parent out of their own children
# behind `require_verified_email`; a reset link nobody receives is a dead end
# under the sign-in form that takes the password with it. Off, the app says
# so; on, both flows come back with nothing to rebuild — the routes, the
# tokens, the mailers and the views all stay live behind this switch.
#
# Flip it in the same change that configures delivery.
module Mailing
  ENABLED = false

  def self.enabled?
    ENABLED
  end
end
