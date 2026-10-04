class CreateFriendships < ActiveRecord::Migration[8.0]
  def change
    create_table :friendships do |t|
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :addressee, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.datetime :accepted_at

      t.timestamps
    end

    # One friendship per pair, whichever way round it was asked. The reverse
    # pair is caught in the model, which has to look both ways anyway.
    add_index :friendships, [ :requester_id, :addressee_id ], unique: true
    add_index :friendships, [ :addressee_id, :status ]

    add_column :users, :friend_code, :string
    add_index :users, :friend_code, unique: true

    # Presence. A column rather than a cache store because the app has none,
    # and this is one small write per user per minute at most.
    add_column :users, :last_seen_at, :datetime
    add_index :users, :last_seen_at

    # A duel addressed to one person. Null for every room in the public queue,
    # which is still how most duels start.
    add_reference :challenges, :invited_user, foreign_key: { to_table: :users }
  end
end
