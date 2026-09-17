# Lets a controller name the thing that just happened, for Analytics.
#
#   track :signup, role: user.role
#
# Every action worth an event ends in a redirect, and the script that sends the
# event only exists in the browser — so the event rides the flash to the page
# the redirect lands on and is written into its <head> there (see
# shared/_analytics). The flash is the right carrier and not a hack: it is
# already how this app hands a completed answer's XP and badges to the next
# screen, it survives exactly one redirect, and it is dropped whether or not
# anything read it, so a queued event cannot turn up an hour later attached to
# some unrelated page.
#
# One event per request, deliberately. Nothing here fires two, and a slot that
# cannot hold two is a slot nobody has to wonder about the ordering of.
module TrackedEvents
  extend ActiveSupport::Concern

  KEY = :analytics

  included do
    helper_method :tracked_event
  end

  def track(key, **props)
    flash[KEY] = {
      "name" => Analytics.event_name(key),
      # Stringified on the way in rather than on the way out: the flash is
      # serialized to the session cookie as JSON, which would turn the symbols
      # into strings anyway, and a value that changes shape in transit is the
      # kind of thing that works in a test and not in a browser.
      "props" => props.compact.transform_keys(&:to_s).transform_values(&:to_s)
    }
  end

  # What shared/_analytics renders, or nil on the overwhelming majority of
  # requests, which are nothing in particular.
  def tracked_event
    event = flash[KEY]
    return nil unless event.is_a?(Hash) && event["name"].present?

    event
  end
end
