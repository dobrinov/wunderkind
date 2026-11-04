# Two things a parent with no child in their account needed:
#
# * `pending_link_code` — a child's link code typed before the parent's own
#   address is confirmed. Taking hold of an account somebody else made still
#   waits on that confirmation (Parents::BaseController), but the code is kept
#   rather than refused, and confirming the address makes the link
#   (User#verify!) — the parents who typed a code and were told „first confirm
#   your email" had left.
# * `child_reminders_sent` — ChildReminder now writes twice, a few days in and
#   about a week in, so „was it sent" became „how many times".
class AddPendingLinkAndReminderCountToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :pending_link_code, :string
    add_column :users, :child_reminders_sent, :integer, null: false, default: 0
    execute "UPDATE users SET child_reminders_sent = 1 WHERE child_reminder_sent_at IS NOT NULL"
  end

  def down
    remove_column :users, :pending_link_code
    remove_column :users, :child_reminders_sent
  end
end
