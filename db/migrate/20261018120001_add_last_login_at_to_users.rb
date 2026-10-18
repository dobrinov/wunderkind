class AddLastLoginAtToUsers < ActiveRecord::Migration[8.0]
  # When somebody last signed in — with a password, by signing up, or, for a
  # managed child who has no password of their own, by a parent switching into
  # their profile. Unlike last_seen_at it is not stamped on every request, so it
  # answers „who came back" rather than „who is here". Read by the admin users
  # list, which sorts by it. NULL for every account until its next sign-in.
  def change
    add_column :users, :last_login_at, :datetime
    add_index :users, :last_login_at
  end
end
