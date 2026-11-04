# Two nudges to a parent who has not added a child: a few days after sign-up,
# and once more about a week in. Never a third.
#
# A parent account with no child in it does nothing at all. For an
# unconfirmed address the email's button is a fresh confirmation link (the one
# from sign-up expires in two days), whose first use also signs the parent in
# and opens the new-child form — or links the child whose code they typed
# meanwhile (User#claim_pending_child!) — see ParentMailer#child_reminder.
#
# `users.child_reminders_sent` counts them and `child_reminder_sent_at` holds
# the last, stamped whether or not the parent goes on to add anyone. An
# account older than WINDOW is never written to, so the first run does not
# reach back to every parent who signed up and walked away months ago. Run
# daily by `rake reminders:children`.
module ChildReminder
  AFTER = 3.days
  SECOND_AFTER = 8.days
  # Never two reminders closer than this, whatever the dates of sign-up.
  GAP = 4.days
  WINDOW = 14.days

  def self.recipients(now: Time.current)
    candidates = User.parent.where.not(email: nil).where.not(id: ParentLink.select(:parent_id)).
      where(created_at: (now - WINDOW)..)
    first = candidates.where(child_reminders_sent: 0).where(created_at: ..(now - AFTER))
    second = candidates.where(child_reminders_sent: 1).where(created_at: ..(now - SECOND_AFTER)).
      where(child_reminder_sent_at: ..(now - GAP))
    first.or(second)
  end

  def self.deliver(parent)
    ParentMailer.child_reminder(parent, second: parent.child_reminders_sent.positive?).deliver_now
    parent.update_columns(child_reminder_sent_at: Time.current, child_reminders_sent: parent.child_reminders_sent + 1)
  end
end
