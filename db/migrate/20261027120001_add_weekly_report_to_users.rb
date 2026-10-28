# The parent's weekly email: whether they want it (on unless they say no —
# the settings and every email's footer turn it off), and the Monday of the
# last week they were sent, so running the task twice sends nothing twice.
class AddWeeklyReportToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :weekly_report, :boolean, null: false, default: true
    add_column :users, :weekly_report_sent_on, :date
  end
end
