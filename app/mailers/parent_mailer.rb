class ParentMailer < ApplicationMailer
  # See WeeklyReport. Built here from the week rather than handed a report, so
  # the mail can be queued and still say what the week said when it is sent.
  def weekly_report(parent, week_start)
    @parent = parent
    @report = WeeklyReport.new(parent, week_start: week_start)
    token = parent.generate_token_for(:email_preferences)
    @unsubscribe_url = email_unsubscribe_url(token, :weekly_report)
    @preferences_url = email_preferences_url(token)

    # One-click unsubscribe (RFC 8058): the large providers show their own
    # button for it and expect it of anything sent weekly.
    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

    I18n.with_locale(parent.locale.presence || I18n.default_locale) do
      mail to: parent.email,
           subject: t("mailers.weekly_report.subject",
                      names: @report.children.map { |entry| entry.child.name }.to_sentence,
                      dates: @report.dates_label)
    end
  end

  # „Деян те кани в семейството на Мая и Боян" — the link to accept, and the
  # code beside it for someone who would rather type. Sent only while Mailing
  # is on (Parents::FamilyInvitationsController); otherwise the inviter passes
  # the same link on by hand. Not an optional email: it was asked for by
  # somebody who knows this address, once.
  def family_invitation(invitation)
    @invitation = invitation
    @inviter = invitation.inviter
    @children = invitation.children.map(&:name).to_sentence
    @url = family_invitation_url(invitation.token)

    # In the inviter's language: the invitee has no account yet to ask, and a
    # family usually shares one.
    I18n.with_locale(@inviter.locale.presence || I18n.default_locale) do
      mail to: invitation.email, subject: t("mailers.family_invitation.subject", name: @inviter.name)
    end
  end
end
