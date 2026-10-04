class CreateGoalsAndRewards < ActiveRecord::Migration[8.0]
  # A parent's standing intent for a child, and the rewards it has earned.
  #
  # Progress is never stored — it is measured from user_answers whenever
  # anybody looks, the same way PracticeHistory is. What *is* stored is the
  # moment a period was completed, because that is the thing a child must not
  # lose when a parent edits the goal afterwards: `goal_awards.reward` is a
  # snapshot of the words that were promised, not a pointer to today's.
  def change
    create_table :goals do |t|
      t.references :parent, null: false, foreign_key: { to_table: :users }
      t.references :child, null: false, foreign_key: { to_table: :users }

      t.integer :metric, null: false          # minutes / problems / correct
      t.integer :mode, null: false            # daily (a day at a time) / total (cumulative)
      t.integer :period, null: false          # week / month / once
      t.integer :target, null: false          # qualifying days, or the count
      t.integer :threshold                    # per-day bar; daily mode only

      t.date :starts_on, null: false
      t.date :ends_on                         # `once` only
      t.text :reward, null: false
      t.datetime :archived_at

      t.timestamps
    end

    create_table :goal_awards do |t|
      t.references :goal, null: false, foreign_key: true
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.text :reward, null: false
      t.datetime :earned_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    # One award per period, which is also what makes awarding idempotent: it is
    # recomputed on every read, so the index is the thing that stops a second
    # look paying a second time.
    add_index :goal_awards, [ :goal_id, :period_start ], unique: true
  end
end
