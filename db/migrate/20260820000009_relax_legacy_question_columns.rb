class RelaxLegacyQuestionColumns < ActiveRecord::Migration[8.0]
  # text/answer are superseded by body/grading; they stay (nullable) until the
  # migrated data has proven grading parity in production, then get dropped.
  def change
    change_column_null :questions, :text, true
    change_column_null :questions, :answer, true
  end
end
