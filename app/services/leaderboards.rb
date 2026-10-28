# Leaderboards are queries over the append-only xp_events, never separate state.
module Leaderboards
  Entry = Struct.new(:user, :xp, :rank, keyword_init: true)

module_function

# Monday 00:00 in Sofia, which is when every board resets.
def week_start
  Time.use_zone("Europe/Sofia") { Time.zone.now.beginning_of_week }
end

# The global board: every student with a nickname, since a board is shown by
# nickname and a student without one has nothing to be shown as.
def global(from: week_start)
  weekly_xp(User.student.where.not(nickname: [ nil, "" ]).to_a, from: from)
end


  def weekly_xp(users, from: Time.current.beginning_of_week)
    totals = XpEvent.where(user: users, created_at: from..).group(:user_id).sum(:amount)

    entries = users.map { |user| Entry.new(user: user, xp: totals.fetch(user.id, 0)) }
    entries.sort_by! { |entry| [ -entry.xp, entry.user.name ] }
    entries.each_with_index { |entry, index| entry.rank = index + 1 }
    entries
  end
end
