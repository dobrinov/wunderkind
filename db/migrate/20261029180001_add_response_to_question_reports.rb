# An admin closing a report now answers the student who filed it: what was
# fixed, or why there was nothing to fix. `response_seen_at` is when the student
# read the answer on „Днес".
#
# Reports closed before this had no answer to read, so they are marked seen —
# otherwise every child who ever reported anything would be greeted by a pile
# of empty replies about questions they have long forgotten.
class AddResponseToQuestionReports < ActiveRecord::Migration[8.0]
  def up
    add_column :question_reports, :response, :text
    add_column :question_reports, :response_seen_at, :datetime

    execute <<~SQL
      UPDATE question_reports SET response_seen_at = resolved_at WHERE status <> 0
    SQL
  end

  def down
    remove_column :question_reports, :response
    remove_column :question_reports, :response_seen_at
  end
end
