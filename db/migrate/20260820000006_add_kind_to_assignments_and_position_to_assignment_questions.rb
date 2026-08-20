class AddKindToAssignmentsAndPositionToAssignmentQuestions < ActiveRecord::Migration[8.0]
  def up
    add_column :assignments, :kind, :integer, default: 0, null: false
    add_column :assignment_questions, :position, :integer

    execute <<~SQL
      UPDATE assignment_questions SET position = numbered.rn
      FROM (SELECT id, row_number() OVER (PARTITION BY assignment_id ORDER BY id) AS rn FROM assignment_questions) numbered
      WHERE assignment_questions.id = numbered.id
    SQL

    change_column_null :assignment_questions, :position, false
    add_index :assignment_questions, [ :assignment_id, :position ], unique: true
  end

  def down
    remove_column :assignments, :kind
    remove_column :assignment_questions, :position
  end
end
