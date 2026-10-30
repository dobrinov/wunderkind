# Whether a managed child may be in friends' leagues was a boolean defaulting
# to false, which also locked out every child a parent had created *with* a
# login of their own — all twelve in the family field test, who asked their
# mother one by one. NULL now means "the parent has not said": a child with a
# login of their own is in, one without is not (User#leagues_on?). Every false
# in the table is that default — no parent ever had a way to set false without
# having first set true — so they all become NULL.
class LeaguesAllowedUnsetByDefault < ActiveRecord::Migration[8.1]
  def up
    change_column_null :users, :leagues_allowed, true
    change_column_default :users, :leagues_allowed, from: false, to: nil
    execute "UPDATE users SET leagues_allowed = NULL WHERE leagues_allowed = false"
  end

  def down
    execute "UPDATE users SET leagues_allowed = false WHERE leagues_allowed IS NULL"
    change_column_default :users, :leagues_allowed, from: nil, to: false
    change_column_null :users, :leagues_allowed, false
  end
end
