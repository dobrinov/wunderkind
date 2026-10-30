class ApplicationMailer < ActionMailer::Base
  default from: -> { Mailing.from }, reply_to: -> { Mailing.reply_to }
  layout "mailer"
  helper EmailHelper

  # Every email is in Bulgarian, whatever locale the request or job that sent
  # it ran under: the people this app writes to are Bulgarian families, and an
  # English mail would only ever be a mistake (a job queued from a test, a
  # stray `users.locale`).
  around_action { |_mailer, action| I18n.with_locale(:bg, &action) }
end
