class CreateTopicPrerequisites < ActiveRecord::Migration[8.0]
  def change
    create_table :topic_prerequisites do |t|
      t.references :topic, null: false, foreign_key: true
      t.references :prerequisite, null: false, foreign_key: { to_table: :topics }

      t.timestamps
    end
    add_index :topic_prerequisites, [ :topic_id, :prerequisite_id ], unique: true
  end
end
