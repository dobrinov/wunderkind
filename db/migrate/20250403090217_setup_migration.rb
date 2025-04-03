class SetupMigration < ActiveRecord::Migration[8.0]
  def change
    # Create questions table with polymorphic association
    create_table :questions do |t|
      t.string :questionable_type, null: false
      t.integer :questionable_id, null: false
      t.integer :minimum_age, null: false
      t.timestamps
    end
    add_index :questions, [:questionable_type, :questionable_id]

    # Create kenguru_questions table first
    create_table :kenguru_questions do |t|
      t.text :text, null: false
      t.integer :year, null: false
      t.integer :grade, null: false
      t.integer :index, null: false
      t.timestamps
    end
    add_index :kenguru_questions, [:year, :grade, :index], unique: true

    # Create kenguru_answers table
    create_table :kenguru_answers do |t|
      t.references :kenguru_question, null: false, foreign_key: true
      t.text :text, null: false
      t.boolean :correct, null: false, default: false
      t.timestamps
    end
    add_index :kenguru_answers, [:kenguru_question_id, :correct], unique: true, where: "correct = true"
  end
end
