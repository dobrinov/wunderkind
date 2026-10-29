# Features come forward one at a time (FeatureVisibility): which of them this
# person has been introduced to, whether they have had the first-run tour, and
# a parent's switch to skip all of it for a child who already knows the app.
#
# Everyone who signed up before this ships has seen the app as it was, so they
# are marked introduced to everything and toured — a „Ново за теб" sheet about
# duels to a child who duels every week would be a sheet about nothing.
class AddFeatureIntroductionsToUsers < ActiveRecord::Migration[8.0]
  FEATURES = %w[review duel friends leaderboards badges competitions suggest].freeze

  def up
    add_column :users, :introduced_features, :string, array: true, null: false, default: []
    add_column :users, :toured_at, :datetime
    add_column :users, :show_all_features, :boolean, null: false, default: false

    execute <<~SQL
      UPDATE users
      SET introduced_features = ARRAY[#{FEATURES.map { |f| connection.quote(f) }.join(", ")}]::varchar[],
          toured_at = now()
    SQL
  end

  def down
    remove_column :users, :introduced_features
    remove_column :users, :toured_at
    remove_column :users, :show_all_features
  end
end
