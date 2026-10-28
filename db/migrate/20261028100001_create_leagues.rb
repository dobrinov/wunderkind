class CreateLeagues < ActiveRecord::Migration[8.0]
  def change
    create_table :leagues do |t|
      t.string :name, null: false
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :code, null: false
      t.timestamps
    end
    add_index :leagues, :code, unique: true

    create_table :league_memberships do |t|
      t.references :league, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :league_memberships, [ :league_id, :user_id ], unique: true

    # A child whose account a parent holds takes part only when that parent says
    # so — see League.
    add_column :users, :leagues_allowed, :boolean, null: false, default: false
  end
end
