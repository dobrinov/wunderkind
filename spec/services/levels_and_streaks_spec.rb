require "rails_helper"

describe Levels do
  it "maps XP to levels along the quadratic curve" do
    Levels.level_for(0).should eq(1)
    Levels.level_for(49).should eq(1)
    Levels.level_for(50).should eq(2)
    Levels.level_for(200).should eq(3)
    Levels.level_for(4999).should eq(10)
  end

  it "reports progress toward the next level" do
    Levels.progress(0).should eq(0.0)
    Levels.progress(25).should eq(0.5)
  end
end

describe Streaks do
  let(:user) { create(:user) }
  let(:today) { Date.new(2026, 8, 20) }

  it "starts a streak on first activity" do
    Streaks.record(user, on: today)

    user.current_streak.should eq(1)
    user.last_active_on.should eq(today)
  end

  it "does not double-count the same day" do
    Streaks.record(user, on: today)
    Streaks.record(user, on: today)

    user.current_streak.should eq(1)
  end

  it "extends the streak on consecutive days" do
    Streaks.record(user, on: today)
    Streaks.record(user, on: today + 1)

    user.current_streak.should eq(2)
    user.longest_streak.should eq(2)
  end

  it "resets after a missed day with no freeze" do
    Streaks.record(user, on: today)
    Streaks.record(user, on: today + 2)

    user.current_streak.should eq(1)
  end

  it "bridges a single missed day by consuming a freeze" do
    user.streak_freezes = 1
    Streaks.record(user, on: today)
    Streaks.record(user, on: today + 2)

    user.current_streak.should eq(2)
    user.streak_freezes.should eq(0)
  end

  it "earns a freeze every full week, capped" do
    date = today
    Streaks.record(user, on: date)
    13.times { date += 1; Streaks.record(user, on: date) }

    user.current_streak.should eq(14)
    user.streak_freezes.should eq(Streaks::MAX_FREEZES)
  end
end
