class CreateHomeworks < ActiveRecord::Migration[8.0]
  def change
    create_table :homeworks do |t|
      t.references :assigner, null: false, foreign_key: { to_table: :users }
      t.references :classroom, foreign_key: true
      t.string :title, null: false
      t.datetime :due_at, null: false

      t.timestamps
    end

    create_table :homework_questions do |t|
      t.references :homework, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps
    end
    add_index :homework_questions, [ :homework_id, :question_id ], unique: true
    add_index :homework_questions, [ :homework_id, :position ], unique: true

    add_reference :assignments, :homework, foreign_key: true
  end
end
