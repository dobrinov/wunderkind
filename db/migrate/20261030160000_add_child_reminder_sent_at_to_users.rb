class AddChildReminderSentAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :child_reminder_sent_at, :datetime
  end
end
