require "rails_helper"

# Coins: fifteen tracks counted from rows that already exist, one award row per
# rung reached. What each track counts — and, as much, what it refuses to.
describe Coins do
  let(:student) { create(:user, elo: 1200, placed_at: 10.days.ago, climb_base_elo: 1200) }

  def answer!(question, correct:, at: Time.current, kind: :practice, hints: 0, rating: 1200, question_rating: nil, skipped: false)
    travel_to(at) do
      assignment = Assignment.create!(user: student, kind: kind)
      row = assignment.assignment_questions.create!(question: question, position: 1)
      row.create_user_answer!(user: student, value: "1", correct: correct && !skipped, skipped: skipped,
                              response: { "value" => "1", "hints_used" => hints },
                              rating_before: rating, question_rating_before: question_rating || question.elo)
    end
  end

  describe "Научих я!" do
    it "counts a mistake answered right at least three days later, in ordinary practice" do
      learned, too_soon, recalled = create_list(:question, 3)
      answer!(learned, correct: false, at: 5.days.ago)
      answer!(learned, correct: true, at: 1.day.ago)
      answer!(too_soon, correct: false, at: 2.days.ago)
      answer!(too_soon, correct: true, at: 1.day.ago)
      answer!(recalled, correct: false, at: 5.days.ago)
      answer!(recalled, correct: true, at: 1.day.ago, kind: :mistakes)

      Coins.count(student, "learned").should eq(1)
    end
  end

  it "climbs from where placement put the student" do
    student.update!(elo: 1260)
    Coins.count(student, "climb").should eq(60)
  end

  it "counts a topic up 100 from its first measured rating, on enough answers" do
    up = Topic.create!(name: "Дроби")
    thin = Topic.create!(name: "Ъгли")
    student.skills.create!(topic: up, rating: 1350, base_rating: 1200, games_count: 20)
    student.skills.create!(topic: thin, rating: 1350, base_rating: 1200, games_count: 5)

    Coins.count(student, "topic_up").should eq(1)
  end

  it "counts above my level only with no hint, measured, 100 or more over the student" do
    hard = create(:question, elo: 1400)
    answer!(hard, correct: true, question_rating: 1310)
    answer!(create(:question), correct: true, question_rating: 1310, hints: 1)
    answer!(create(:question), correct: true, question_rating: 1250)
    answer!(create(:question), correct: true, question_rating: 1400, kind: :mistakes)

    Coins.count(student, "above_level").should eq(1)
  end

  it "counts the longest clean run at or above the target, broken by a hint or a skip" do
    target = Dispatcher.target_rating(1200)
    3.times { answer!(create(:question), correct: true, question_rating: target) }
    answer!(create(:question), correct: true, question_rating: target, hints: 1)
    2.times { answer!(create(:question), correct: true, question_rating: target) }
    answer!(create(:question), correct: false, skipped: true)
    answer!(create(:question), correct: true, question_rating: target - 300)

    Coins.count(student, "clean_run").should eq(3)
  end

  it "counts weeks with practice on four days or more, and never resets" do
    monday = Time.zone.today.beginning_of_week - 14
    [ 0, 1, 2, 3 ].each { |day| answer!(create(:question), correct: true, at: (monday + day).in_time_zone + 10.hours) }
    [ 7, 8 ].each { |day| answer!(create(:question), correct: true, at: (monday + day).in_time_zone + 10.hours) }

    Coins.count(student, "full_week").should eq(1)
  end

  it "comes back on a second day in the first week" do
    answer!(create(:question), correct: true, at: 6.days.ago)
    Coins.count(student, "came_back").should eq(0)
    answer!(create(:question), correct: false, at: 3.days.ago)
    Coins.count(student, "came_back").should eq(1)
  end

  it "counts a report the team fixed, and a suggestion it accepted and others solved" do
    question = create(:question)
    QuestionReport.create!(question: question, user: student, reason: :wrong_answer, status: :resolved)
    QuestionReport.create!(question: create(:question), user: student, reason: :typo, status: :dismissed)
    mine = create(:question, suggested_by_id: student.id)
    other = create(:user)
    assignment = Assignment.create!(user: other)
    row = assignment.assignment_questions.create!(question: mine, position: 1)
    row.create_user_answer!(user: other, value: "1", correct: true, response: { "value" => "1" })

    Coins.count(student, "detective").should eq(1)
    Coins.count(student, "author").should eq(1)
    Coins.count(student, "solved_mine").should eq(1)
    Coins.visible_tracks(student).map(&:key).should include("solved_mine")
  end

  it "keeps the promise and duel tracks out of sight until they are possible" do
    keys = Coins.visible_tracks(student).map(&:key)
    keys.should_not include("promise", "duels", "rematch", "solved_mine")
  end

  describe ".refresh!" do
    it "mints one row per rung reached, once, and stamps them seen when silent" do
      learned = create(:question)
      answer!(learned, correct: false, at: 5.days.ago)
      answer!(learned, correct: true, at: 1.day.ago)

      minted = Coins.refresh!(student)
      minted.map { |award| [ award.badge_key, award.rung ] }.should include([ "learned", 1 ])
      Coins.refresh!(student).should be_empty
      Coins.unseen(student).should_not be_empty

      other = create(:user, climb_base_elo: 1100, elo: 1150)
      Coins.refresh!(other, silent: true).map(&:badge_key).should eq(%w[climb climb])
      Coins.unseen(other).should be_empty
    end
  end

  it "mints rung n in material n, and a one-coin track in the best" do
    learned = Coins.find("learned")
    (1..7).map { |rung| learned.material(rung) }.should eq(Coins::MATERIALS)
    Coins.find("came_back").material(1).should eq("diamond")
  end
end
