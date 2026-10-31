# Private leaderboards — „класации с приятели". A league is a name, an owner,
# a code and its members, and Monday resets it with the global board.
#
# **A league is not ranked by XP.** The people in one are friends and siblings
# of every age, and XP is paid per answer: a first-grader rattling through
# times-table facts out-earned a twelfth-grader on a page of logarithms every
# week (the family field test, 2026-10-30), so the table said who answers
# fastest, not who worked. A league point is effort against the child's own
# daily goal instead: each day pays up to DAY_POINTS, in proportion to the
# practice minutes against `daily_minutes_target`, and stops there — so a week
# is worth at most 700 to anybody, a five-minute child who keeps their five
# minutes every day is level with a thirty-minute one who keeps theirs, and
# grinding past the goal buys nothing. Ties go to the week's XP. The global
# board stays on XP: it is strangers, and makes no claim to be fair between
# ages.
#
# How you get in mirrors how you make a friend: the owner adds friends — people
# who already accepted each other — and anybody else needs the league's code,
# which a member had to hand them. There is no search and no browsing.
module Leagues
  Result = Struct.new(:league, :error, keyword_init: true) do
    def ok? = error.nil?
  end

  # A ranked row, or — for a member with nothing yet this week — an unranked
  # one: a list ending in „Теа Н. — 0" reads to a child as being singled out,
  # so those are listed under the rest as not having practised yet.
  Standing = Struct.new(:user, :points, :goal_days, :xp, :rank, keyword_init: true)

  DAY_POINTS = 100

  # One answer counts for at most this much time: a problem left open while
  # the child went to dinner is not ten minutes of practice. The answer flow
  # already clamps a duration to 30 minutes; this is tighter, for a table
  # that children compare.
  ANSWER_CAP_MS = 5.minutes.in_milliseconds

  module_function

  # Friends the owner may add: accepted friends who are allowed in leagues at
  # all. Anything else posted in friend_ids is dropped rather than refused — a
  # stale form is not worth an error page.
  def create!(owner, name:, friend_ids: [])
    return Result.new(error: :not_allowed) unless owner.may_join_leagues?
    return Result.new(error: :too_many) if owner.owned_leagues.count >= League::MAX_OWNED

    league = League.new(owner: owner, name: name.to_s.strip)
    return Result.new(league: league, error: :invalid) unless league.valid?

    friends = owner.friends.where(id: Array(friend_ids)).select(&:may_join_leagues?)
    League.transaction do
      league.save!
      ([ owner ] + friends).first(League::MAX_MEMBERS).each { |user| league.memberships.create!(user: user) }
    end
    Result.new(league: league)
  end

  def join!(user, code)
    league = League.find_by(code: code.to_s.strip.upcase.presence)

    return Result.new(error: :not_allowed) unless user.may_join_leagues?
    return Result.new(error: :unknown_code) if league.nil?
    return Result.new(league: league, error: :already_member) if league.member?(user)
    return Result.new(league: league, error: :full) if league.full?

    league.memberships.create!(user: user)
    Result.new(league: league)
  rescue ActiveRecord::RecordNotUnique
    Result.new(league: league, error: :already_member)
  end

  # Leaving your own league hands it to whoever has been in it longest; the
  # last one out takes it with them.
  def leave!(user, league)
    League.transaction do
      league.memberships.where(user: user).delete_all
      next unless league.owned_by?(user)

      heir = league.memberships.order(:created_at, :id).first&.user
      heir ? league.update!(owner: heir) : league.destroy!
    end
  end

  # The owner taking somebody out — never themselves (that is leave!).
  def remove!(owner, league, member)
    return false unless league.owned_by?(owner) && member.id != owner.id

    league.memberships.where(user: member).delete_all.positive?
  end

  def standings(league, from: Leaderboards.week_start)
    members = league.members.to_a
    xp = Leaderboards.weekly_xp(members, from: from).to_h { |entry| [ entry.user.id, entry.xp ] }
    effort = effort(members, from: from)

    rows = members.map do |user|
      points, goal_days = effort.fetch(user.id, [ 0, 0 ])
      Standing.new(user: user, points: points, goal_days: goal_days, xp: xp.fetch(user.id, 0))
    end
    rows.sort_by! { |row| [ -row.points, -row.xp, row.user.name ] }
    rank = 0
    rows.each do |row|
      next unless row.points.positive?

      rank += 1
      row.rank = rank
    end
    rows
  end

  # { user_id => [points, days the goal was met] } for the week from `from`:
  # practice minutes per Sofia day (answers, not skips — the effort scope a
  # parent's goal reads too), each day worth DAY_POINTS at the child's own
  # target and never more.
  def effort(users, from:)
    targets = users.to_h { |user| [ user.id, (user.daily_minutes_target || DailyPractice::DEFAULT_MINUTES) * 60_000 ] }
    day = Arel.sql("(user_answers.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Sofia')::date")
    per_day = UserAnswer.attempted.where(user_id: targets.keys, created_at: from..)
                        .group(:user_id, day)
                        .sum(Arel.sql("LEAST(COALESCE(user_answers.duration_ms, 0), #{ANSWER_CAP_MS})"))

    per_day.each_with_object(Hash.new { |hash, key| hash[key] = [ 0, 0 ] }) do |((user_id, _date), ms), totals|
      share = [ ms.to_f / targets[user_id], 1.0 ].min
      totals[user_id][0] += (share * DAY_POINTS).round
      totals[user_id][1] += 1 if share >= 1.0
    end
  end
end
