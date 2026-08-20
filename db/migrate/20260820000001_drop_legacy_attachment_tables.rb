class DropLegacyAttachmentTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :file_attachments, if_exists: true
    drop_table :script_attachments, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
