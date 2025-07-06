class AddEloToUsersAndQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :elo, :integer, null: false, default: 1200
    add_column :questions, :elo, :integer, null: false, default: 1200
  end
end
