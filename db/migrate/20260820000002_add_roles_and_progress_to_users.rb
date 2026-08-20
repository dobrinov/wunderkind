class AddRolesAndProgressToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :role, :integer, default: 0, null: false
    add_column :users, :nickname, :string
    add_column :users, :locale, :string, default: "bg", null: false
    add_column :users, :daily_minutes_target, :integer
    add_column :users, :total_xp, :integer, default: 0, null: false
    add_column :users, :current_streak, :integer, default: 0, null: false
    add_column :users, :longest_streak, :integer, default: 0, null: false
    add_column :users, :last_active_on, :date
    add_column :users, :streak_freezes, :integer, default: 0, null: false

    execute "UPDATE users SET role = 3 WHERE admin = TRUE"
    remove_column :users, :admin

    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
  end

  def down
    remove_index :users, name: "index_users_on_lower_email"
    add_column :users, :admin, :boolean, default: false, null: false
    execute "UPDATE users SET admin = TRUE WHERE role = 3"
    remove_column :users, :role, :nickname, :locale, :daily_minutes_target, :total_xp,
                  :current_streak, :longest_streak, :last_active_on, :streak_freezes
  end
end
