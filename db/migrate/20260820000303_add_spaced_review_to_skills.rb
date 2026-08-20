class AddSpacedReviewToSkills < ActiveRecord::Migration[8.0]
  def change
    add_column :skills, :review_interval_days, :integer, null: false, default: 1
    add_column :skills, :mastered_at, :datetime
  end
end
