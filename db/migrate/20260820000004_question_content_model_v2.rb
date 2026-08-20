class QuestionContentModelV2 < ActiveRecord::Migration[8.0]
  def up
    add_column :questions, :body, :jsonb
    add_column :questions, :body_text, :text
    add_column :questions, :answer_type, :integer, default: 1, null: false
    add_column :questions, :grading, :jsonb, default: {}, null: false
    add_column :questions, :status, :integer, default: 0, null: false
    add_column :questions, :grade_min, :integer
    add_column :questions, :grade_max, :integer
    add_reference :questions, :author, foreign_key: { to_table: :users }, index: true

    add_column :possible_answers, :correct, :boolean, default: false, null: false
    add_column :possible_answers, :position, :integer, default: 0, null: false

    # Existing content: plain text becomes a single-paragraph rich document.
    execute <<~SQL
      UPDATE questions SET
        body = jsonb_build_object(
          'type', 'doc',
          'content', jsonb_build_array(
            jsonb_build_object(
              'type', 'paragraph',
              'content', jsonb_build_array(jsonb_build_object('type', 'text', 'text', text))
            )
          )
        ),
        body_text = text,
        status = 3
    SQL

    # Questions with options are multiple choice; the rest grade as exact values.
    execute <<~SQL
      UPDATE questions SET answer_type = 0
      WHERE EXISTS (SELECT 1 FROM possible_answers WHERE possible_answers.question_id = questions.id)
    SQL
    execute <<~SQL
      UPDATE questions SET grading = jsonb_build_object('expected', answer)
      WHERE answer_type = 1
    SQL

    execute <<~SQL
      UPDATE possible_answers SET correct = TRUE
      FROM questions
      WHERE possible_answers.question_id = questions.id AND possible_answers.value = questions.answer
    SQL
    # Multiple-choice questions whose stored answer never matched an option get one added,
    # so every MC question has exactly one gradable truth.
    execute <<~SQL
      INSERT INTO possible_answers (question_id, value, correct, created_at, updated_at)
      SELECT q.id, q.answer, TRUE, NOW(), NOW()
      FROM questions q
      WHERE q.answer_type = 0
        AND NOT EXISTS (SELECT 1 FROM possible_answers pa WHERE pa.question_id = q.id AND pa.correct)
    SQL
    execute <<~SQL
      UPDATE possible_answers SET position = numbered.rn
      FROM (SELECT id, row_number() OVER (PARTITION BY question_id ORDER BY id) AS rn FROM possible_answers) numbered
      WHERE possible_answers.id = numbered.id
    SQL

    change_column_null :questions, :body, false
    change_column_null :questions, :body_text, false
  end

  def down
    remove_reference :questions, :author
    remove_column :questions, :body, :body_text, :answer_type, :grading, :status, :grade_min, :grade_max
    remove_column :possible_answers, :correct, :position
  end
end
