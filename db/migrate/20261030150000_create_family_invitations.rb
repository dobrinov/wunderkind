# Two parents, one family: a parent invites another grown-up — by email, or by
# a six-character code read out across the kitchen — and accepting links them
# to every child the inviter has at that moment (FamilyInvitation#accept!).
#
# The token is the link's secret and the code is the one a person types; both
# are single-use, so an invitation is spent the moment somebody accepts it.
# `name_for_children` is what the children call a parent („Мама"), shown
# wherever a child reads who asked something of them.
class CreateFamilyInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :family_invitations do |t|
      t.references :inviter, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.string :email
      t.string :token, null: false
      t.string :code, null: false
      t.datetime :expires_at, null: false
      t.references :accepted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :accepted_at
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :family_invitations, :token, unique: true
    add_index :family_invitations, :code, unique: true

    add_column :users, :name_for_children, :string
  end
end
