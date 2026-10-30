# One nudge, a few days after sign-up, to a parent who has not added a child.
#
# A parent account with no child in it does nothing at all, and the commonest
# reason is not a change of mind but the address: adding a child is a POST
# behind `require_verified_email`, and the confirmation link from sign-up
# expires in two days. So the email asks for whichever is in the way — for an
# unconfirmed address, a fresh confirmation link first, then the child; for a
# confirmed one, just the child.
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
