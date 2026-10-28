# Private leaderboards — „класации с приятели". A league is a name, an owner,
# a code and its members; the standings are the same weekly XP the global
# board reads (Leaderboards.weekly_xp), so a point is worth the same in every
# list a child is on, and Monday resets them all together.
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
  Standing = Struct.new(:user, :xp, :rank, keyword_init: true)

  module_function

  def week_start
    Time.use_zone("Europe/Sofia") { Time.zone.now.beginning_of_week }
  end

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

  def standings(league, from: week_start)
    entries = Leaderboards.weekly_xp(league.members.to_a, from: from)
    rank = 0
    entries.map do |entry|
      rank += 1 if entry.xp.positive?
      Standing.new(user: entry.user, xp: entry.xp, rank: (rank if entry.xp.positive?))
    end
  end
end
