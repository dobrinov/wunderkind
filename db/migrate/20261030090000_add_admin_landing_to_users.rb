# Where an admin who is also a parent lands after signing in: the side they
# were on last (the default), always the family, or always the admin area.
class AddAdminLandingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :admin_landing, :string, null: false, default: "last"
  end
end
