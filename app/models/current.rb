# Per-request memo, reset by Rails between requests and between tests.
class Current < ActiveSupport::CurrentAttributes
  # The calendar (Competitions.all), read once per request from the tables.
  attribute :competitions
end
