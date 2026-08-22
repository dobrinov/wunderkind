class CreateQuestionReports < ActiveRecord::Migration[8.0]
  def change
    create_table :question_reports do |t|
      # index: false — the unique pair below already covers question_id.
      t.references :question, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.integer :reason, null: false
      t.text :note
      t.integer :status, null: false, default: 0
      t.references :resolver, foreign_key: { to_table: :users }
      t.datetime :resolved_at

      t.timestamps
    end

    # One row per student per question: a second report replaces the first
    # rather than piling another copy of the same complaint into the queue.
    add_index :question_reports, [ :question_id, :user_id ], unique: true
    add_index :question_reports, :status
  end
end
