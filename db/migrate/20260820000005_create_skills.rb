class CreateSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :skills do |t|
      t.references :user, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.integer :rating, null: false, default: 1200
      t.integer :games_count, null: false, default: 0
      t.datetime :last_practiced_at
      t.datetime :review_due_at

      t.timestamps
    end

    add_index :skills, [ :user_id, :topic_id ], unique: true
  end
end
