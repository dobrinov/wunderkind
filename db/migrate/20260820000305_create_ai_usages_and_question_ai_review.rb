class CreateAiUsagesAndQuestionAiReview < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_usages do |t|
      t.date :month, null: false, index: { unique: true }
      t.integer :cost_cents, null: false, default: 0
      t.integer :calls, null: false, default: 0

      t.timestamps
    end

    add_column :questions, :ai_review, :jsonb
  end
end
