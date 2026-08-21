class AddNotTaughtSkips < ActiveRecord::Migration[8.0]
  def change
    add_column :user_answers, :skipped, :boolean, default: false, null: false
    add_column :skills, :deferred_until, :datetime
  end
end
