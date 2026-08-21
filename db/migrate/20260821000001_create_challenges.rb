class CreateChallenges < ActiveRecord::Migration[8.0]
  def change
    create_table :challenges do |t|
      t.integer :status, null: false, default: 0
      t.integer :question_count, null: false
      t.integer :seconds_per_question, null: false
      t.integer :target_elo, null: false
      t.datetime :started_at
      t.datetime :finished_at
      t.references :winner, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :challenges, [ :status, :target_elo, :created_at ]

    create_table :challenge_questions do |t|
      t.references :challenge, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps
    end
    add_index :challenge_questions, [ :challenge_id, :position ], unique: true
    add_index :challenge_questions, [ :challenge_id, :question_id ], unique: true

    create_table :challenge_participants do |t|
      t.references :challenge, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :score, null: false, default: 0
      t.integer :correct_count, null: false, default: 0
      t.integer :total_ms, null: false, default: 0
      t.integer :xp_earned, null: false, default: 0
      t.datetime :question_started_at
      t.datetime :finished_at

      t.timestamps
    end
    add_index :challenge_participants, [ :challenge_id, :user_id ], unique: true

    create_table :challenge_answers do |t|
      t.references :challenge_participant, null: false, foreign_key: true
      t.references :challenge_question, null: false, foreign_key: true
      t.string :value, null: false
      t.jsonb :response, null: false, default: {}
      t.boolean :correct, null: false
      t.integer :duration_ms, null: false
      t.integer :points, null: false, default: 0

      t.timestamps
    end
    add_index :challenge_answers,
              [ :challenge_participant_id, :challenge_question_id ],
              unique: true,
              name: "index_challenge_answers_on_participant_and_question"
  end
end
