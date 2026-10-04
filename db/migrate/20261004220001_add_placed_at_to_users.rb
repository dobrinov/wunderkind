class AddPlacedAtToUsers < ActiveRecord::Migration[8.0]
  # When a student finished the placement session that set their rating. NULL
  # means they never did one — either they signed up before placement existed,
  # or they skipped it — and those fall back to Dispatcher's calibration ladder
  # exactly as before. See Placement.
  def change
    add_column :users, :placed_at, :datetime
  end
end
