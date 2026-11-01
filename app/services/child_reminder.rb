# One nudge, a few days after sign-up, to a parent who has not added a child.
#
# A parent account with no child in it does nothing at all. For an
# unconfirmed address the email's button is a fresh confirmation link (the one
# from sign-up expires in two days), whose first use also signs the parent in
# and opens the new-child form — see ParentMailer#child_reminder.
#
# Exactly once: `users.child_reminder_sent_at` is stamped whether or not the
# parent goes on to add anyone, and an account older than WINDOW is never
# written to, so the first run does not reach back to every parent who signed
# up and walked away months ago. Run daily by `rake reminders:children`.
module ChildReminder
  AFTER = 3.days
  WINDOW = 14.days

  def self.recipients(now: Time.current)
    User.parent.where.not(email: nil).where(child_reminder_sent_at: nil).
      where(created_at: (now - WINDOW)..(now - AFTER)).
      where.not(id: ParentLink.select(:parent_id))
  end

  def self.deliver(parent)
    ParentMailer.child_reminder(parent).deliver_now
    parent.update_column(:child_reminder_sent_at, Time.current)
  end
end
