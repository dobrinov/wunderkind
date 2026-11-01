# The ladder family a problem was written in (tools/authoring): the same idea
# at rising ratings, its variants reworded, renamed and re-dressed. Read by
# Templates, which keeps a session to one problem of each.
class AddFamilyToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :family, :string
    add_index :questions, :family, where: "family IS NOT NULL"
  end
end
