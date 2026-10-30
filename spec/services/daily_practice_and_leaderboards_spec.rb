require "rails_helper"

describe DailyPractice do
  let(:user) { create(:user, elo: 1200, daily_minutes_target: 10) }

  it "sizes the session to the daily target using the default pace when no history exists" do
    create_list(:question, 15, elo: 1200)

    assignment = DailyPractice.execute(user:)

    # 10 minutes at 45s per question ≈ 13, capped at MAX_QUESTIONS.
    assignment.questions.count.should eq(DailyPractice::MAX_QUESTIONS)
    assignment.kind.should eq("daily")
  end

  it "sizes from the student's real pace, not from the placement" do
    create_list(:question, 20, elo: 1200)
    placement = Assignment.create!(user: user, kind: :placement)
    8.times do |index|
      row = placement.assignment_questions.create!(question: create(:question, elo: 1200), position: index + 1)
      row.create_user_answer!(user: user, value: "1", correct: true, response: { "value" => "1" }, duration_ms: 3_000)
    end

    # Eight three-second placement answers would have made this the cap; the
    # default pace makes it 13, capped at 12 all the same — so slow the pace.
    user.update!(daily_minutes_target: 5)
    DailyPractice.execute(user:).questions.count.should eq(7)
  end

  it "resumes today's unfinished session instead of starting another" do
    create_list(:question, 30, elo: 1200)
    first = DailyPractice.execute(user:)
    row = first.assignment_questions.first
    row.create_user_answer!(user: user, value: "42", correct: true, response: { "value" => "42" })

    DailyPractice.execute(user:).should eq(first)

    first.assignment_questions.each_with_index do |each, index|
      next if index.zero?

      each.create_user_answer!(user: user, value: "42", correct: true, response: { "value" => "42" })
    end
    DailyPractice.execute(user:).should_not eq(first)
  end

  it "does not hand back a problem answered in the last fortnight" do
    questions = create_list(:question, 30, elo: 1200)
    old = Assignment.create!(user: user, kind: :practice)
    questions.first(4).each_with_index do |question, index|
      row = old.assignment_questions.create!(question: question, position: index + 1)
      row.create_user_answer!(user: user, value: "42", correct: true, response: { "value" => "42" })
    end

    DailyPractice.execute(user:).questions.should_not include(*questions.first(4))
  end

  it "falls back to the default target without a configured one" do
    user.update!(daily_minutes_target: nil)
    create_list(:question, 25, elo: 1200)

    # DEFAULT_MINUTES (10) at 45s per question, capped.
    DailyPractice.execute(user:).questions.count.should eq(DailyPractice::MAX_QUESTIONS)
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
