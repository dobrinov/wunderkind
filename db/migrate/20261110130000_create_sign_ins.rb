# One row per sign-in, so /overseer/stats can draw them by day.
# users.last_login_at only ever held the latest, which answers „who came
# back" and nothing about when. `via` is how: a password, signing up, the
# email verification link, or — for a managed child with no password of their
# own — a parent switching into the profile (SignIn::VIAS).
#
# Nothing is backfilled. The one thing known about the past is each account's
# last sign-in, and a chart built from those would show the days before this
# table as quieter than they were; AdminStats#sign_ins_since says where the
# record starts instead.
class CreateSignIns < ActiveRecord::Migration[8.1]
  def change
    create_table :sign_ins do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :via, null: false
      t.datetime :created_at, null: false
    end
    add_index :sign_ins, :created_at
  end
end
