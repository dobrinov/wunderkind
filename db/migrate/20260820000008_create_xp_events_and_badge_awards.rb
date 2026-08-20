class CreateXpEventsAndBadgeAwards < ActiveRecord::Migration[8.0]
  def change
    create_table :xp_events do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount, null: false
      t.string :reason, null: false
      t.references :source, polymorphic: true
      t.datetime :created_at, null: false
    end
    add_index :xp_events, [ :user_id, :created_at ]

    create_table :badge_awards do |t|
      t.references :user, null: false, foreign_key: true
      t.string :badge_key, null: false
      t.datetime :created_at, null: false
    end
    add_index :badge_awards, [ :user_id, :badge_key ], unique: true
  end
end
