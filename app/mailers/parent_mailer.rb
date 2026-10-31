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

    # Up to three children by first name; a bigger family is „the children",
    # since twelve names leave no room in an inbox line for the dates.
    names = @report.children.map { |entry| entry.child.name.split.first }
    subject = if names.size <= 3
      t("mailers.weekly_report.subject", names: names.to_sentence, dates: @report.dates_label)
    else
      t("mailers.weekly_report.subject_family", dates: @report.dates_label)
    end
    mail to: parent.email, subject: subject
  end

  # „Деян те кани в семейството на Мая и Боян" — the link to accept, and the
  # code beside it for someone who would rather type. Sent only while Mailing
  # is on (Parents::FamilyInvitationsController); otherwise the inviter passes
  # the same link on by hand. Not an optional email: it was asked for by
  # somebody who knows this address, once.
  def family_invitation(invitation)
    @invitation = invitation
    @inviter = invitation.inviter
    names = invitation.children.map(&:name)
    @children = names.to_sentence
    @children_count = names.size
    @url = family_invitation_url(invitation.token)

    subject = names.any? ? t("mailers.family_invitation.subject", name: @inviter.name, children: @children) : t("mailers.family_invitation.subject_no_children", name: @inviter.name)
    mail to: invitation.email, subject:
  end

  # See ChildReminder: a parent who signed up days ago and has no child in the
  # account yet. An unconfirmed address is asked for first, with a fresh link —
  # the one from sign-up has expired by now, and without it the child cannot be
  # added at all.
  def child_reminder(parent)
    @user = parent
    @verify_url = verify_email_url(token: parent.generate_token_for(:email_verification)) unless parent.verified?
    @add_url = new_parents_child_url

    mail to: parent.email, subject: t(@verify_url ? "mailers.child_reminder.subject_verify" : "mailers.child_reminder.subject")
  end
end
