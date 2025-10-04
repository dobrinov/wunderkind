class CreateQuestionImages < ActiveRecord::Migration[8.0]
  def change
    create_table :question_images do |t|
      t.timestamps
    end
  end
end
