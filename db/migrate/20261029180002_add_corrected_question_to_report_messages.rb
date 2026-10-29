# A team message can point at the corrected version of the reported question
# when the fix is a different row — a reworded problem re-imported as a new
# question, with the old one retired — rather than an edit of the same one.
class AddCorrectedQuestionToReportMessages < ActiveRecord::Migration[8.0]
  def change
    add_reference :question_report_messages, :corrected_question,
                  foreign_key: { to_table: :questions, on_delete: :nullify }
  end
end
