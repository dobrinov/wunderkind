# Awards as coins (Coins): fifteen tracks, one row per rung reached, instead of
# nineteen medals. Most of the 30 medals in production were given on a first
# day by accident (Ранно пиле, Гигантоубиец) or for things that measure nothing
# (perfect_session in a mistakes session); everything real behind them is
# re-earned by `rake coins:backfill`, so the rows go rather than keeping a
# second award style alive.
#
# Three numbers the tracks need and nothing stored before:
#   users.climb_base_elo         where „Изкачване" counts from (placement's
#                                rating; existing accounts start from today's)
#   skills.base_rating           a topic's first measured rating („Тема напред")
#   user_answers.rating_before / question_rating_before
#                                the student's and the problem's ratings at the
#                                moment of the answer („Над нивото", „Чиста серия")
class CoinAwards < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM badge_awards"
    add_column :badge_awards, :rung, :integer, null: false, default: 1
    add_column :badge_awards, :seen_at, :datetime
    remove_index :badge_awards, [ :user_id, :badge_key ], if_exists: true
    add_index :badge_awards, [ :user_id, :badge_key, :rung ], unique: true

    add_column :users, :climb_base_elo, :integer
    execute "UPDATE users SET climb_base_elo = elo"

    add_column :skills, :base_rating, :integer
    execute "UPDATE skills SET base_rating = rating WHERE games_count > 0"

    add_column :user_answers, :rating_before, :integer
    add_column :user_answers, :question_rating_before, :integer
  end

  def down
    remove_column :user_answers, :question_rating_before
    remove_column :user_answers, :rating_before
    remove_column :skills, :base_rating
    remove_column :users, :climb_base_elo
    remove_index :badge_awards, [ :user_id, :badge_key, :rung ]
    remove_column :badge_awards, :seen_at
    remove_column :badge_awards, :rung
  end
end
