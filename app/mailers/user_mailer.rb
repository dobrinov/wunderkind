class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @token = user.generate_token_for(:email_verification)

    mail to: user.email, subject: I18n.t("mailers.email_verification.subject")
  end

  def password_reset(user)
    @user = user
    @token = user.generate_token_for(:password_reset)

    mail to: user.email, subject: I18n.t("mailers.password_reset.subject")
  end
end
