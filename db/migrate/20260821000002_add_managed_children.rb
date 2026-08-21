class AddManagedChildren < ActiveRecord::Migration[8.0]
  def change
    # A child too young for an email has no login of their own: the account is
    # created inside a parent's and reached by switching profiles there, so the
    # address the rest of the app signs people in with is now optional.
    change_column_null :users, :email, true
    add_reference :users, :managed_by, foreign_key: { to_table: :users }
  end
end
