class AddAttachmentFields < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :attachable_type, :string
    add_column :questions, :attachable_id, :bigint
    add_column :questions, :attachable_parameters, :jsonb

    add_check_constraint :questions,
                        "(attachable_id IS NULL) OR (attachable_id IS NOT NULL AND attachable_type IS NOT NULL)",
                         name: "questions_attachable_consistency"
  end
end
