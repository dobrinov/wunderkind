# Where a problem came from, when it is not ours: a past paper of a competition
# or a МОН exam („Софийски математически турнир 2024 · 3 клас · задача 5"), or
# one of ours written on the model of one. Shown on the problem, and what
# „Минали теми" builds a real paper from. See PastPapers.
#
# A past paper sat as a whole is a mock assignment that also names its year and
# grade, so its clock and its points are the paper's own.
class AddSourceToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :source, :jsonb
    add_index :questions, "(source ->> 'competition')", name: "index_questions_on_source_competition",
              where: "source IS NOT NULL"

    add_column :assignments, :paper_year, :integer
    add_column :assignments, :paper_grade, :integer
  end
end
