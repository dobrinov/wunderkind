# Competitions as data with a year in them. A competition (the Софийски
# математически турнир, НВО 7) has editions — one a year, each with its own
# format and its rounds — so a child enters СМТ 2026 rather than „the
# tournament", a past paper belongs to an edition, and next year is a new
# edition rather than an edit of this one. Edited at /overseer/competitions;
# db/seeds/competitions.yml is the first import (`rails competitions:import`).
#
# Texts a page shows in both languages are jsonb {"bg": …, "en": …}.
class CreateCompetitions < ActiveRecord::Migration[8.1]
  def change
    create_table :competitions do |t|
      t.string :slug, null: false, index: { unique: true }
      t.string :kind, null: false
      t.string :short
      t.jsonb :name, null: false, default: {}
      t.string :organizer, null: false
      t.integer :grade_min, null: false
      t.integer :grade_max, null: false
      t.string :style, null: false
      t.string :url
      t.string :archive_url
      t.jsonb :topic_names, null: false, default: []
      t.integer :programme_from
      t.integer :programme_to
      t.jsonb :description, null: false, default: {}
      t.jsonb :format, null: false, default: {}
      t.integer :grade_page
      t.timestamps
    end

    create_table :competition_editions do |t|
      t.references :competition, null: false, foreign_key: true
      t.integer :year, null: false
      t.jsonb :format
      t.jsonb :note
      t.timestamps
      t.index [ :competition_id, :year ], unique: true
    end

    create_table :competition_rounds do |t|
      t.references :competition_edition, null: false, foreign_key: true
      t.jsonb :name, null: false, default: {}
      t.date :date, null: false
      t.boolean :approximate, null: false, default: false
      t.jsonb :note
      t.timestamps
    end
  end
end
