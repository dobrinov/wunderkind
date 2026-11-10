# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.dsn = ENV["SENTRY_DSN"]
  # Off: with it on, every error report carried the request's form body and
  # cookies — a sign-in that raised sent the password, the email and a
  # replayable session cookie, and a new-child form the child's name. The
  # gem does not read Rails' filter_parameters, so the only safe setting for
  # an app full of children's accounts is not to send them at all.
  config.send_default_pii = false
  config.enabled_environments = %w[production]
end
