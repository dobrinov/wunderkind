# Who in a report's conversation wrote a message: the student who reported it,
# the family (a parent of that student, who can now take part), or the team.
# Stored rather than worked out from the author, because a parent can also be
# an admin and an author's account can be deleted.
#
# Every message so far was the reporter's or the team's.
class AddSideToQuestionReportMessages < ActiveRecord::Migration[8.0]
  def up
    add_column :question_report_messages, :side, :integer, null: false, default: 1
    execute <<~SQL
      UPDATE question_report_messages m SET side = 0
      FROM question_reports r
      WHERE r.id = m.question_report_id AND m.author_id = r.user_id
    SQL
  end

  def down
    remove_column :question_report_messages, :side
  end
end
