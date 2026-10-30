# A parent's PIN for leaving a child's profile on a shared tablet (User#profile_pin).
class AddProfilePinDigestToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :profile_pin_digest, :string
  end
end
