class CreateQuestionScripts < ActiveRecord::Migration[8.0]
  def change
    create_table :question_scripts do |t|
      t.text :code, null: false
      t.timestamps
    end
  end
end
