class ApplicationMailer < ActionMailer::Base
  default from: -> { Mailing.from }
  layout "mailer"
end
