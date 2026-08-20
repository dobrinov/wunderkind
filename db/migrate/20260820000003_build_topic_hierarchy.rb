class BuildTopicHierarchy < ActiveRecord::Migration[8.0]
  def change
    add_column :topics, :slug, :string
    add_column :topics, :position, :integer, default: 0, null: false
    add_reference :topics, :parent, foreign_key: { to_table: :topics }, index: true

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE topics
          SET slug = trim(both '-' from regexp_replace(lower(name), '[^a-z0-9а-я]+', '-', 'g')) || '-' || id
        SQL
        change_column_null :topics, :slug, false
      end
    end

    add_index :topics, :slug, unique: true

    add_index :questions_topics, [ :question_id, :topic_id ], unique: true
    add_index :questions_topics, :topic_id
  end
end
