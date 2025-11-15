class RemoveQuestionCountFromAssignments < ActiveRecord::Migration[8.0]
  def change
    remove_column :assignments, :question_count, :integer, null: false, default: 10
  end
end
