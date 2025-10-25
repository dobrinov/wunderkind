class Topics < ActiveRecord::Migration[8.0]
  def change
    create_table :topics do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_join_table :topics, :questions
  end
end
