require "rails_helper"

describe "Badges progress" do
  let(:user) { create(:user) }

  it "reports progress for a countable badge and none for a one-shot one" do
    stats = Badges::Stats.new(sessions: 7, answers: 0, streak: 0, level: 1, mastered_topics: 0, duel_wins: 0)

    countable = Badges.find("sessions_10")
    countable.should be_countable
    countable.progress_for(stats).to_s.should eq("7/10")
    countable.progress_for(stats).fraction.should eq(0.7)

    # A progress bar that can only ever read 0/1 tells a child nothing.
    one_shot = Badges.find("early_bird")
    one_shot.should_not be_countable
    one_shot.progress_for(stats).should be_nil
  end

  it "never reports more than the target, however far past it the count is" do
    stats = Badges::Stats.new(sessions: 0, answers: 0, streak: 400, level: 1, mastered_topics: 0, duel_wins: 0)
    progress = Badges.find("streak_100").progress_for(stats)

    progress.to_s.should eq("100/100")
    progress.fraction.should eq(1.0)
  end

  it "gathers the counts a progress lambda reads from the user" do
    user.update!(current_streak: 4, total_xp: 500)
    stats = Badges.stats_for(user)

    stats.streak.should eq(4)
    stats.level.should eq(user.level)
    stats.sessions.should eq(0)
    stats.answers.should eq(0)
    stats.duel_wins.should eq(0)
  end

  it "measures a level badge from level 1, where every account starts" do
    fresh = Badges::Stats.new(sessions: 0, answers: 0, streak: 0, level: 1, mastered_topics: 0, duel_wins: 0)
    progress = Badges.find("level_5").progress_for(fresh)

    # The label still reads the level a child recognises, but no distance has
    # been travelled yet, so the bar is empty.
    progress.to_s.should eq("1/5")
    progress.fraction.should eq(0.0)

    midway = Badges::Stats.new(sessions: 0, answers: 0, streak: 0, level: 3, mastered_topics: 0, duel_wins: 0)
    Badges.find("level_5").progress_for(midway).fraction.should eq(0.5)
  end

  it "does not offer a level badge to an account that has done nothing" do
    fresh = Badges::Stats.new(sessions: 0, answers: 0, streak: 0, level: 1, mastered_topics: 0, duel_wins: 0)

    badge, progress = Badges.next_to_unlock(user, stats: fresh, awarded_keys: [])

    # Being level 1 is not a head start over every badge sitting at zero.
    badge.key.should_not eq("level_5")
    progress.fraction.should eq(0.0)
  end

  it "picks the unearned countable badge closest to unlocking" do
    stats = Badges::Stats.new(sessions: 1, answers: 3, streak: 2, level: 1, mastered_topics: 0, duel_wins: 0)

    badge, progress = Badges.next_to_unlock(user, stats: stats, awarded_keys: [])

    # 2/3 of a three-day streak beats 1/10 sessions and 3/100 answers.
    badge.key.should eq("streak_3")
    progress.to_s.should eq("2/3")
  end

  it "skips badges already awarded" do
    stats = Badges::Stats.new(sessions: 1, answers: 3, streak: 2, level: 1, mastered_topics: 0, duel_wins: 0)

    badge, = Badges.next_to_unlock(user, stats: stats, awarded_keys: [ "streak_3" ])

    badge.key.should_not eq("streak_3")
  end

  it "has nothing to point at when every countable badge is earned or complete" do
    stats = Badges::Stats.new(sessions: 999, answers: 999, streak: 999, level: 99, mastered_topics: 99, duel_wins: 99)

    Badges.next_to_unlock(user, stats: stats, awarded_keys: []).should be_nil
  end

  it "still awards badges from the same definitions" do
    Badges.check!(user, type: :session_completed, assignment: Assignment.create!(user:))

    user.badge_awards.pluck(:badge_key).should include("first_session")
  end
end
