# The email that tells a student the team has written on a question they
# reported. On by default, like every optional email (EmailPreferences).
class AddReportActivityToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :report_activity, :boolean, null: false, default: true
  end
end
