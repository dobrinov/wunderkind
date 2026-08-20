# Leaderboards are queries over the append-only xp_events, never separate state.
module Leaderboards
  Entry = Struct.new(:user, :xp, :rank, keyword_init: true)

  module_function

  def weekly_xp(users, from: Time.current.beginning_of_week)
    totals = XpEvent.where(user: users, created_at: from..).group(:user_id).sum(:amount)

    entries = users.map { |user| Entry.new(user: user, xp: totals.fetch(user.id, 0)) }
    entries.sort_by! { |entry| [ -entry.xp, entry.user.name ] }
    entries.each_with_index { |entry, index| entry.rank = index + 1 }
    entries
  end
end
