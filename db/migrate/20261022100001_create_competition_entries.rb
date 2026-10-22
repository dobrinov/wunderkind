class CreateCompetitionEntries < ActiveRecord::Migration[8.0]
  def change
    # „Ще участвам". The competitions themselves live in config/competitions.yml,
    # written by a person, so a row here names one by slug rather than by a
    # foreign key — and by season, because the same child enters the same
    # Kangaroo every spring and last year's entry must not stand in for this
    # year's.
    create_table :competition_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :competition_slug, null: false
      t.string :season, null: false

      t.timestamps
    end

    add_index :competition_entries, [ :user_id, :competition_slug, :season ], unique: true,
              name: "index_competition_entries_on_user_competition_season"

    # Which competition a `kind: :competition` session was preparing for, so the
    # session can say so and the next one can be offered from its summary.
    add_column :assignments, :competition_slug, :string
  end
end
