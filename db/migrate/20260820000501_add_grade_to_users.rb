class AddGradeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :grade, :integer

    add_index :questions, :elo
    add_index :questions, [ :grade_min, :grade_max ]
  end
end
