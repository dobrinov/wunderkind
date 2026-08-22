class AddSuggestedByToQuestions < ActiveRecord::Migration[8.0]
  def change
    # Distinct from author_id on purpose: a teacher authors library questions
    # without expecting a byline, but a suggestion is credited to its suggester
    # wherever the question is asked.
    add_reference :questions, :suggested_by, foreign_key: { to_table: :users }
  end
end
