# Placement used to leave the topic ratings it created on the way at the floor
# rating every new account starts with (see Placement.finish!). Every student
# placed before that was fixed still has them: topics never played, rated far
# below the student, which aims a parent's focus and exam preparation at
# first-grade problems. Lift those to the student's rating; a row any measured
# game has moved is left alone.
class LiftUnplayedSkillsToPlacedRating < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE skills SET rating = users.elo, updated_at = now()
      FROM users
      WHERE skills.user_id = users.id
        AND users.placed_at IS NOT NULL
        AND skills.games_count = 0
        AND skills.rating < users.elo
    SQL
  end

  def down
    # Nothing to put back: the floor was never a measurement.
  end
end
