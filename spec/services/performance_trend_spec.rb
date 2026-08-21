require "rails_helper"

describe PerformanceTrend do
  let(:user) { create(:user) }
  let(:assignment) { Assignment.create!(user:) }
  let(:today) { Date.new(2026, 8, 20) } # a Thursday

  def answer_on(date, elo:, correct: true, skipped: false)
    assignment_question = assignment.assignment_questions.create!(
      question: create(:question, elo:), position: assignment.assignment_questions.count + 1
    )
    UserAnswer.create!(
      user:, assignment_question:, value: "42", correct:, skipped:,
      response: { "value" => "42" }, created_at: date.in_time_zone.change(hour: 12)
    )
  end

  def trend = PerformanceTrend.new(user, today: today)

  it "plots the average difficulty of the questions answered correctly, by week" do
    answer_on(today - 14, elo: 1000)
    answer_on(today - 14, elo: 1100)
    answer_on(today, elo: 1300)

    by_week = trend.weeks.index_by(&:starts_on)

    by_week[(today - 14).beginning_of_week].rating.should eq(1050)
    by_week[today.beginning_of_week].rating.should eq(1300)
  end

  it "leaves wrong and skipped answers out of the difficulty but counts attempts" do
    answer_on(today, elo: 1200)
    answer_on(today, elo: 2800, correct: false)
    answer_on(today, elo: 2800, correct: false, skipped: true)

    week = trend.weeks.last

    week.rating.should eq(1200)
    week.answers.should eq(2)
    week.correct.should eq(1)
    week.accuracy.should eq(50)
  end

  it "leaves a week the student sat out as a gap rather than a zero" do
    answer_on(today - 14, elo: 1000)
    answer_on(today, elo: 1200)

    quiet = trend.weeks.find { |week| week.starts_on == (today - 7).beginning_of_week }

    quiet.should_not be_solved
    quiet.rating.should be_nil
    trend.points.size.should eq(2)
  end

  it "needs two points before it is a trend" do
    trend.should_not be_enough
    answer_on(today, elo: 1200)
    trend.should_not be_enough
    answer_on(today - 7, elo: 1100)
    trend.should be_enough
    trend.delta.should eq(100)
  end

  it "opens the scale around a flat run rather than magnifying it" do
    answer_on(today - 7, elo: 1200)
    answer_on(today, elo: 1205)

    low, high = trend.scale

    (high - low).should be >= PerformanceTrend::MIN_SPAN
    low.should be < 1200
    high.should be > 1205
  end

  it "keeps every point inside its own frame" do
    answer_on(today - 7, elo: 900)
    answer_on(today, elo: 1500)

    trend.points.each do |point|
      trend.y_for(point.rating).should be_between(0.0, 1.0).exclusive
    end
  end

  it "draws only the band boundaries that fall inside the frame" do
    answer_on(today - 7, elo: 1180)
    answer_on(today, elo: 1220)

    low, high = trend.scale
    thresholds = trend.band_lines.map(&:first)

    thresholds.should include(1200)
    thresholds.should_not include(1600)
    thresholds.each { |threshold| threshold.should be_between(low, high).exclusive }
    trend.band_lines.assoc(1200).last.should eq(I18n.t("rating_band.strong"))
  end
end
