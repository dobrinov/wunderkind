require "rails_helper"

describe PracticeHistory do
  let(:user) { create(:user) }
  let(:assignment) { Assignment.create!(user:) }
  let(:today) { Date.new(2026, 8, 20) } # a Thursday

  # A fresh question each time: an assignment may hold a given question once.
  def answer_on(date, correct:, skipped: false)
    assignment_question = assignment.assignment_questions.create!(
      question: create(:question, answer: "5"), position: assignment.assignment_questions.count + 1
    )
    UserAnswer.create!(
      user:, assignment_question:, value: "5", correct:, skipped:,
      response: { "value" => "5" }, created_at: date.in_time_zone.change(hour: 12)
    )
  end

  it "starts on a Monday so each column of the strip is one week" do
    history = PracticeHistory.new(user, today: today)

    history.days.first.date.should be_monday
    history.weeks.each { |week| week.size.should eq(7) }
  end

  it "counts attempted answers per day and leaves skips out" do
    answer_on(today, correct: true)
    answer_on(today, correct: false)
    answer_on(today, correct: false, skipped: true)
    answer_on(today - 3, correct: true)

    history = PracticeHistory.new(user, today: today)
    by_date = history.days.index_by(&:date)

    by_date[today].count.should eq(2)
    by_date[today].correct.should eq(1)
    by_date[today - 3].count.should eq(1)
    by_date[today - 1].count.should eq(0)
  end

  it "totals only what it counted" do
    2.times { answer_on(today, correct: true) }
    answer_on(today - 1, correct: false)
    answer_on(today, correct: false, skipped: true)

    history = PracticeHistory.new(user, today: today)

    history.total_answers.should eq(3)
    history.total_correct.should eq(2)
    history.active_days.should eq(2)
    history.accuracy.should eq(67)
  end

  it "has no accuracy to report before the first answer" do
    PracticeHistory.new(user, today: today).accuracy.should be_nil
  end

  it "steps the shade by how much work a day held" do
    days = PracticeHistory::Day
    days.new(date: today, count: 0, correct: 0).level.should eq(0)
    days.new(date: today, count: 4, correct: 0).level.should eq(1)
    days.new(date: today, count: 9, correct: 0).level.should eq(2)
    days.new(date: today, count: 40, correct: 0).level.should eq(3)
  end

  it "gives the streak dots this calendar week, Monday to Sunday" do
    week = PracticeHistory.new(user, today: today).week

    week.size.should eq(7)
    week.first.date.should eq(today.beginning_of_week)
    week.last.date.should eq(today.end_of_week)
    week.first.date.should be_monday

    # Days still to come are in the row, and say so.
    week.select { |day| day.future?(today) }.map(&:date).should eq([ today + 1, today + 2, today + 3 ])
  end
end
