require "rails_helper"

describe DailyPractice do
  let(:user) { create(:user, elo: 1200, daily_minutes_target: 10) }

  it "sizes the session to the daily target using the default pace when no history exists" do
    create_list(:question, 15, elo: 1200)

    assignment = DailyPractice.execute(user:)

    # 10 minutes at 45s per question ≈ 13 questions.
    assignment.questions.count.should eq(13)
    assignment.kind.should eq("daily")
  end

  it "falls back to the default target without a configured one" do
    user.update!(daily_minutes_target: nil)
    create_list(:question, 25, elo: 1200)

    DailyPractice.execute(user:).questions.count.should eq(20)
  end
end

describe Leaderboards do
  it "ranks users by XP earned since the given time, including zero scorers" do
    fast, slow, idle = create_list(:user, 3)
    Xp.award!(fast, amount: 30, reason: "answer")
    Xp.award!(slow, amount: 10, reason: "answer")
    XpEvent.create!(user: idle, amount: 99, reason: "answer", created_at: 2.weeks.ago)

    entries = Leaderboards.weekly_xp([ fast, slow, idle ])

    entries.map { |entry| [ entry.rank, entry.user, entry.xp ] }.should eq([
      [ 1, fast, 30 ],
      [ 2, slow, 10 ],
      [ 3, idle, 0 ]
    ])
  end
end
