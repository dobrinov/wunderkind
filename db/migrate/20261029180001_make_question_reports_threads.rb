# A report becomes a conversation, like a ticket: the student files it, the
# team answers, the student says whether the fix fixed it, and somebody closes
# it. `question_report_messages` is the thread — written comments and the
# status changes between them (closed, reopened, withdrawn, the student's
# „оправено е" / „още не е наред"), so the history reads top to bottom.
#
# On the report itself: `in_progress` joins the statuses for a discussion under
# way; `seen_at` is when the student last read their thread, so anything the
# team wrote after it is unread; `archived_at` is the student putting it out of
# sight — a new word from the team brings it back; and `snapshot` keeps the
# question as the student saw it, so a fix can be shown as before and after.
#
# Reports closed before this get one closing entry in their thread, written as
# already read: a child is not to be greeted by a pile of notices about
# questions they have long forgotten.
class MakeQuestionReportsThreads < ActiveRecord::Migration[8.0]
  def up
    create_table :question_report_messages do |t|
      t.references :question_report, null: false, foreign_key: { on_delete: :cascade }
      t.references :author, foreign_key: { to_table: :users, on_delete: :nullify }
      t.integer :kind, null: false, default: 0
      t.text :body
      t.timestamps
    end
    add_index :question_report_messages, [ :question_report_id, :created_at ]

    add_column :question_reports, :seen_at, :datetime
    add_column :question_reports, :archived_at, :datetime
    add_column :question_reports, :snapshot, :jsonb

    # kind: 1 resolved, 2 dismissed — the same numbers as the report statuses.
    execute <<~SQL
      INSERT INTO question_report_messages (question_report_id, author_id, kind, created_at, updated_at)
      SELECT id, resolver_id, status, COALESCE(resolved_at, updated_at), COALESCE(resolved_at, updated_at)
      FROM question_reports WHERE status IN (1, 2)
    SQL
    execute "UPDATE question_reports SET seen_at = now() WHERE status IN (1, 2)"
  end

  def down
    remove_column :question_reports, :snapshot
    remove_column :question_reports, :archived_at
    remove_column :question_reports, :seen_at
    drop_table :question_report_messages
  end
end
