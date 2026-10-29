# The default daily session drops from 15 to 10 minutes for new students
# (DailyPractice::DEFAULT_MINUTES). A student who never chose a length has
# been practising 15 minutes a day; writing that number down keeps their
# session the length it has always been rather than shortening it unannounced.
class KeepDailyMinutesForExistingStudents < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE users SET daily_minutes_target = 15
      WHERE daily_minutes_target IS NULL AND role = 0
    SQL
  end

  def down
    # Nothing to undo: 15 is what these accounts were getting anyway.
  end
end
