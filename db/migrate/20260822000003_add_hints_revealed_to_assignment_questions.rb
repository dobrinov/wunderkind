# How many rungs of the hint ladder the student has been shown on this
# question, counted by the server as it serves them. The count used to be a
# hidden form field the client reported — with the whole ladder in the DOM —
# so the XP halving for hinted answers ran on the honor system.
class AddHintsRevealedToAssignmentQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :assignment_questions, :hints_revealed, :integer, null: false, default: 0
  end
end
