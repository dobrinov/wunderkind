class RemoveTeachersClassroomsAndHomework < ActiveRecord::Migration[8.0]
  def up
    # Homework sessions stay in each student's history as ordinary practice:
    # the answers in them are real evidence and the calendar links to them.
    execute "UPDATE assignments SET kind = 0, homework_id = NULL WHERE kind = 1"
    remove_column :assignments, :homework_id

    drop_table :homework_questions
    drop_table :homeworks
    drop_table :classroom_memberships
    drop_table :classrooms

    # A teacher account keeps existing as the grown-up role that remains. Their
    # authored questions keep their author_id either way.
    execute "UPDATE users SET role = 2 WHERE role = 1"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
