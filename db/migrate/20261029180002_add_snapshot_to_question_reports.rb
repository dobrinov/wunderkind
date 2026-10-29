# The question as the student saw it when they reported it — the text, the
# options, the accepted answer, the explanation — so „Моите сигнали" can show
# them what changed once an admin has fixed it. Reports filed before this have
# none, and say so.
class AddSnapshotToQuestionReports < ActiveRecord::Migration[8.0]
  def change
    add_column :question_reports, :snapshot, :jsonb
  end
end
