class AddHintAvailability < ActiveRecord::Migration[8.0]
  def change
    # Nullable on purpose: nil means "whatever this kind of session allows",
    # the same convention assignments.feedback_after_answer already uses. Only
    # a caller that wants to depart from the policy writes it.
    add_column :assignments, :hints_allowed, :boolean

    # The teacher's decision for one homework. Off by default: homework is
    # where a teacher looks for what the student can do unaided.
    add_column :homeworks, :hints_allowed, :boolean, null: false, default: false
  end
end
