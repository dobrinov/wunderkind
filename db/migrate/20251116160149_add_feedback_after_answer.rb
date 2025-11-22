class AddFeedbackAfterAnswer < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :feedback_after_answer, :boolean, null: false, default: false
    add_column :assignments, :feedback_after_answer, :boolean
  end
end
