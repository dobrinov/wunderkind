class CreateQuestionHints < ActiveRecord::Migration[8.0]
  def change
    create_table :question_hints do |t|
      t.references :question, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :ladder, null: false, default: []
      t.jsonb :wrong_answer_explanations, null: false, default: {}
      t.string :model
      t.datetime :reviewed_at

      t.timestamps
    end
  end
end
