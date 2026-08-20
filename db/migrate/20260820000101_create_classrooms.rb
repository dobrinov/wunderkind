class CreateClassrooms < ActiveRecord::Migration[8.0]
  def change
    create_table :classrooms do |t|
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :invite_code, null: false
      t.boolean :leaderboard_enabled, null: false, default: true

      t.timestamps
    end
    add_index :classrooms, :invite_code, unique: true

    create_table :classroom_memberships do |t|
      t.references :classroom, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :classroom_memberships, [ :classroom_id, :user_id ], unique: true
  end
end
