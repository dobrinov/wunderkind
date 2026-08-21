# School grades are gone from the model: difficulty is the question's Elo and
# ability is the student's, so a first-grader who can do third-grade work simply
# gets it. See Dispatcher.
class RemoveGrades < ActiveRecord::Migration[8.0]
  def change
    remove_index :questions, column: [ :grade_min, :grade_max ]
    remove_column :questions, :grade_min, :integer
    remove_column :questions, :grade_max, :integer
    remove_column :users, :grade, :integer
  end
end
