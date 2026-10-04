class CreateChallengeTopics < ActiveRecord::Migration[8.0]
  def change
    create_table :challenge_topics do |t|
      t.references :challenge, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true

      t.timestamps
    end

    add_index :challenge_topics, [ :challenge_id, :topic_id ], unique: true
  end
end
