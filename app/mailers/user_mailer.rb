class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @token = user.generate_token_for(:email_verification)

    mail to: user.email, subject: I18n.t("mailers.email_verification.subject")
  end

  # The team wrote on a question this student reported: a comment, a status
  # change, the question taken out to be fixed. One mail per team message, sent
  # only to an address the student confirmed (QuestionReportMessage).
  def report_activity(message)
    @message = message
    @report = message.question_report
    @user = @report.user
    token = @user.generate_token_for(:email_preferences)
    @unsubscribe_url = email_unsubscribe_url(token, :report_activity)
    @preferences_url = email_preferences_url(token)

    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

    I18n.with_locale(@user.locale.presence || I18n.default_locale) do
      mail to: @user.email,
           subject: t("mailers.report_activity.subjects.#{message.kind}",
                      default: t("mailers.report_activity.subjects.comment"))
    end
  end

  def password_reset(user)
    @user = user
    @token = user.generate_token_for(:password_reset)

    mail to: user.email, subject: I18n.t("mailers.password_reset.subject")
  end
end
