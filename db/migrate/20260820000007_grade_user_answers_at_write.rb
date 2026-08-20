class GradeUserAnswersAtWrite < ActiveRecord::Migration[8.0]
  def up
    add_column :user_answers, :correct, :boolean
    add_column :user_answers, :response, :jsonb
    add_column :user_answers, :duration_ms, :integer

    # Historical answers were graded by string equality; preserve those verdicts.
    execute <<~SQL
      UPDATE user_answers SET correct = (questions.answer = user_answers.value)
      FROM assignment_questions
      JOIN questions ON questions.id = assignment_questions.question_id
      WHERE assignment_questions.id = user_answers.assignment_question_id
    SQL
    execute <<~SQL
      UPDATE user_answers SET
        response = jsonb_build_object('value', value),
        duration_ms = LEAST(
          GREATEST((EXTRACT(EPOCH FROM (user_answers.created_at - assignment_questions.created_at)) * 1000)::bigint, 0),
          30 * 60 * 1000
        )
      FROM assignment_questions
      WHERE assignment_questions.id = user_answers.assignment_question_id
    SQL

    change_column_null :user_answers, :correct, false
    change_column_null :user_answers, :response, false
  end

  def down
    remove_column :user_answers, :correct, :response, :duration_ms
  end
end
