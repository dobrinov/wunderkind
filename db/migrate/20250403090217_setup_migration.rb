class SetupMigration < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end

    create_table :questions do |t|
      t.text :text, null: false
      t.text :answer, null: false
      t.text :explanation, null: true
      t.timestamps
    end

    create_table :possible_answers do |t|
      t.references :question, null: false, foreign_key: true
      t.text :value, null: false
      t.timestamps
    end

    create_table :assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :question_count, null: false
      t.timestamp :completed_at

      t.timestamps
    end

    create_table :assignment_questions do |t|
      t.references :assignment, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.timestamps

      t.index [:assignment_id, :question_id], unique: true
    end

    create_table :user_answers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :assignment_question, null: false, foreign_key: true
      t.text :value, null: false
      t.timestamps
    end
  end
end
