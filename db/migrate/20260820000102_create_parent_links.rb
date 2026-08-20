class CreateParentLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :parent_links do |t|
      t.references :parent, null: false, foreign_key: { to_table: :users }
      t.references :child, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :parent_links, [ :parent_id, :child_id ], unique: true

    add_column :users, :link_code, :string
    add_index :users, :link_code, unique: true
  end
end
