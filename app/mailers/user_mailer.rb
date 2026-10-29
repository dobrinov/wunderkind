class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @token = user.generate_token_for(:email_verification)

    mail to: user.email, subject: I18n.t("mailers.email_verification.subject")
  end

  # The team wrote on a question a student reported: a comment, a status
  # change, the question taken out to be fixed. One mail per team message and
  # recipient (QuestionReportMessage#email_recipients) — the student, or a
  # parent of theirs, who is told that it was their child who reported it and
  # is linked to the conversation on the child's page, where they can answer.
  def report_activity(message, recipient)
    @message = message
    @report = message.question_report
    @user = recipient
    @child = @report.user unless recipient == @report.user
    @thread_url = @child ? parents_child_report_url(@child, @report) : report_url(@report)
    token = @user.generate_token_for(:email_preferences)
    @unsubscribe_url = email_unsubscribe_url(token, :report_activity)
    @preferences_url = email_preferences_url(token)

    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

    I18n.with_locale(@user.locale.presence || I18n.default_locale) do
      subject = t("mailers.report_activity.subjects.#{message.kind}", default: t("mailers.report_activity.subjects.comment"))
      subject = t("mailers.report_activity.family_subject", name: @child.name, what: subject) if @child
      mail to: @user.email, subject: subject
    end
  end

  # A child has just reported a question: their parent is told, with what the
  # child said, and linked to the conversation where they can add to it.
  # QuestionReport.file! sends it, for a new report or one reopened.
  def report_filed(report, parent)
    @report = report
    @user = parent
    @child = report.user
    @thread_url = parents_child_report_url(@child, @report)
    token = @user.generate_token_for(:email_preferences)
    @unsubscribe_url = email_unsubscribe_url(token, :report_activity)
    @preferences_url = email_preferences_url(token)

    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

    I18n.with_locale(@user.locale.presence || I18n.default_locale) do
      mail to: @user.email, subject: t("mailers.report_filed.subject", name: @child.name)
    end
  end

  def password_reset(user)
    @user = user
    @token = user.generate_token_for(:password_reset)

    mail to: user.email, subject: I18n.t("mailers.password_reset.subject")
  end
end
