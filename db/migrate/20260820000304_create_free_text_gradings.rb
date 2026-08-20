class CreateFreeTextGradings < ActiveRecord::Migration[8.0]
  def change
    create_table :free_text_gradings do |t|
      t.references :question, null: false, foreign_key: true
      t.string :answer_hash, null: false
      t.string :verdict, null: false
      t.text :feedback

      t.timestamps
    end
    add_index :free_text_gradings, [ :question_id, :answer_hash ], unique: true
  end
end
