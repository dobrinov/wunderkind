# What an admin changed about a question, and when. The bank's rows are
# rewritten in place — a fixed typo, a wrong option made right, an Elo moved
# by hand — and a student's report or an odd skip rate is often only
# explained by what the question said *last week*. Imported questions have no
# rows: the problem file in git is their history.
#
# `diff` holds only the fields that moved, each as [before, after] in the
# form the editor shows them (plain text, option lists, topic names), so a
# revision reads without the row it describes.
class CreateQuestionRevisions < ActiveRecord::Migration[8.0]
  def change
    create_table :question_revisions do |t|
      t.references :question, null: false, foreign_key: { on_delete: :cascade }
      t.references :author, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :action, null: false
      t.jsonb :diff, null: false, default: {}
      t.datetime :created_at, null: false
    end
  end
end
