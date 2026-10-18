class AddAbandonedAtToAssignments < ActiveRecord::Migration[8.0]
  # When StaleSessions closed a session the student walked away from. Such a
  # session also gets completed_at (the time of its last answer), so every
  # "is it over" check reads it as over; this column is what keeps it out of
  # the counts that mean "finished a session" — the session badges.
  def change
    add_column :assignments, :abandoned_at, :datetime
  end
end
