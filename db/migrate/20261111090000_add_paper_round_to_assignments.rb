# A past paper is a year, a grade and, for a competition of several rounds a
# year (Математика без граници), the round: PastPapers::ROUNDS. Nullable, and
# NULL is the main round, so every mock sat before this keeps meaning what it
# did and the release before this one runs on it unchanged.
class AddPaperRoundToAssignments < ActiveRecord::Migration[8.1]
  def change
    add_column :assignments, :paper_round, :string
  end
end
