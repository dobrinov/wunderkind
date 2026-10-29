class CreatePracticeFocuses < ActiveRecord::Migration[8.0]
  # What a parent has asked a child to practise: a few topics, a target, and
  # perhaps a reward — see PracticeFocus.
  #
  # Progress is never stored, the same stance Goals takes: it is read off the
  # child's `skills` rows whenever anybody looks. What is stored is what has to
  # survive the skills moving on — the rating each topic stood at when the focus
  # was set (the „one step forward" target is measured from it), and the moments
  # the focus was completed, celebrated, archived and its reward handed over.
  def change
    create_table :practice_focuses do |t|
      t.references :child, null: false, foreign_key: { to_table: :users }
      t.references :parent, null: false, foreign_key: { to_table: :users }

      t.integer :target, null: false            # mastery / step
      t.text :reward                            # optional, shown to the child verbatim
      t.jsonb :starting_ratings, null: false, default: {}   # topic id => rating when set

      t.datetime :completed_at
      t.datetime :celebrated_at                 # the child has seen the „done" card
      t.datetime :reward_given_at
      t.datetime :archived_at

      t.timestamps
    end

    # One focus in play per child. The database says so rather than trusting the
    # controller to archive the old one first, because two parents of one child
    # can press „Запази" at the same moment.
    add_index :practice_focuses, :child_id, unique: true,
              where: "archived_at IS NULL AND completed_at IS NULL",
              name: "index_practice_focuses_one_active_per_child"

    create_table :practice_focus_topics do |t|
      t.references :practice_focus, null: false, foreign_key: { to_table: :practice_focuses }, index: false
      t.references :topic, null: false, foreign_key: true
    end

    add_index :practice_focus_topics, [ :practice_focus_id, :topic_id ], unique: true
  end
end
