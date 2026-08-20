class RemoveAiIntegration < ActiveRecord::Migration[8.0]
  # AI-backed grading and review tooling is out for now; questions are authored
  # outside the app. Hints stay (manually authored), free-text answers stay
  # (teacher-graded via overrides).
  def change
    drop_table :ai_usages do |t|
      t.date :month, null: false
      t.integer :cost_cents, null: false, default: 0
      t.integer :calls, null: false, default: 0
      t.timestamps
    end

    drop_table :free_text_gradings do |t|
      t.references :question, null: false, foreign_key: true
      t.string :answer_hash, null: false
      t.string :verdict, null: false
      t.text :feedback
      t.timestamps
    end

    remove_column :questions, :ai_review, :jsonb
    disable_extension "pg_trgm"
  end
end
