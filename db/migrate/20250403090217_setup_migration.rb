class SetupMigration < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.boolean :admin, default: false, null: false
      t.timestamps
    end

    create_table :questions do |t|
      t.references :question_attachment
      t.text :text, null: false
      t.text :answer, null: false
      t.text :explanation, null: true
      t.timestamps
    end

    create_table :question_attachments do |t|
      t.string :attachable_type, null: false
      t.integer :attachable_id, null: false
      t.jsonb :attachable_parameters, null: false
      t.timestamps
    end

    create_table :script_attachments do |t|
      t.text :code, null: false
      t.timestamps
    end

    create_table :file_attachments do |t|
    end

    create_table :possible_answers do |t|
      t.references :question, null: false, foreign_key: true
      t.text :value, null: false
      t.timestamps
    end

    create_table :assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :question_count, null: false
      t.timestamp :completed_at

      t.timestamps
    end

    create_table :assignment_questions do |t|
      t.references :assignment, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.timestamps

      t.index [ :assignment_id, :question_id ], unique: true
    end

    create_table :user_answers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :assignment_question, null: false, foreign_key: true
      t.text :value, null: false
      t.timestamps
    end

    primary_key_type, foreign_key_type = primary_and_foreign_key_types

    create_table :active_storage_blobs, id: primary_key_type do |t|
      t.string   :key,          null: false
      t.string   :filename,     null: false
      t.string   :content_type
      t.text     :metadata
      t.string   :service_name, null: false
      t.bigint   :byte_size,    null: false
      t.string   :checksum

      if connection.supports_datetime_with_precision?
        t.datetime :created_at, precision: 6, null: false
      else
        t.datetime :created_at, null: false
      end

      t.index [ :key ], unique: true
    end

    create_table :active_storage_attachments, id: primary_key_type do |t|
      t.string     :name,     null: false
      t.references :record,   null: false, polymorphic: true, index: false, type: foreign_key_type
      t.references :blob,     null: false, type: foreign_key_type

      if connection.supports_datetime_with_precision?
        t.datetime :created_at, precision: 6, null: false
      else
        t.datetime :created_at, null: false
      end

      t.index [ :record_type, :record_id, :name, :blob_id ], name: :index_active_storage_attachments_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    create_table :active_storage_variant_records, id: primary_key_type do |t|
      t.belongs_to :blob, null: false, index: false, type: foreign_key_type
      t.string :variation_digest, null: false

      t.index [ :blob_id, :variation_digest ], name: :index_active_storage_variant_records_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end

  private

  def primary_and_foreign_key_types
    config = Rails.configuration.generators
    setting = config.options[config.orm][:primary_key_type]
    primary_key_type = setting || :primary_key
    foreign_key_type = setting || :bigint
    [ primary_key_type, foreign_key_type ]
  end
end
