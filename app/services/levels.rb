# The XP → level curve: reaching level n costs 50·(n−1)² total XP,
# so early levels come fast and later ones stretch out.
module Levels
  module_function

  def level_for(total_xp)
    Integer.sqrt([ total_xp, 0 ].max / 50) + 1
  end

  def threshold_for(level)
    50 * (level - 1)**2
  end

  # Fraction of the way from the current level to the next, for progress bars.
  def progress(total_xp)
    level = level_for(total_xp)
    floor = threshold_for(level)
    ceiling = threshold_for(level + 1)

    (total_xp - floor).to_f / (ceiling - floor)
  end
end
