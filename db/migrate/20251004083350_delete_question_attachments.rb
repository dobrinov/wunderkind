class DeleteQuestionAttachments < ActiveRecord::Migration[8.0]
  def up
    drop_table :question_attachments
    remove_reference :questions, :question_attachment
  end

  def down
    create_table :question_attachments do |t|
      t.string :attachable_type, null: false
      t.integer :attachable_id, null: false
      t.jsonb :attachable_parameters, null: false
      t.timestamps
    end

    t.references :question_attachment
  end
end
