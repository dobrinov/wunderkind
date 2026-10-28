require "rails_helper"

describe WeeklyReport do
  let(:today) { Date.new(2026, 10, 26) } # a Monday
  let(:week_start) { Date.new(2026, 10, 19) }
  let(:parent) { create(:user, role: :parent, verified_at: Time.current) }
  let(:busy) { User.create_managed_child!(parent:, name: "Ани") }
  let(:idle) { User.create_managed_child!(parent:, name: "Боби") }

  around { |example| travel_to(today.in_time_zone.change(hour: 7)) { example.run } }

  # A fresh question each time: an assignment may hold a given question once.
  def answer(user, date, correct: true)
    assignment = Assignment.create!(user:)
    assignment_question = assignment.assignment_questions.create!(question: create(:question, answer: "5"), position: 1)
    UserAnswer.create!(user:, assignment_question:, value: "5", correct:, response: { "value" => "5" },
                       duration_ms: 60_000, created_at: date.in_time_zone.change(hour: 12))
  end

  it "takes the last full week, Monday to Sunday" do
    WeeklyReport.last_week_start(today).should eq(week_start)
    WeeklyReport.last_week_start(Date.new(2026, 11, 1)).should eq(week_start) # the Sunday after
  end

  it "reports only the children who practised that week" do
    answer(busy, week_start + 1)
    answer(busy, week_start + 2, correct: false)
    answer(idle, week_start - 3) # the week before: not this week's
    idle

    report = WeeklyReport.new(parent, week_start:)

    report.children.map { |entry| entry.child.name }.should eq([ "Ани" ])
    entry = report.children.first
    [ entry.problems, entry.correct, entry.accuracy, entry.active_days, entry.minutes ].should eq([ 2, 1, 50, 2, 2 ])
  end

  it "sends nothing to a parent whose children had a quiet week, and remembers the week" do
    answer(busy, week_start - 2)

    expect { WeeklyReport.deliver(parent, week_start:).should be(false) }.not_to change { ActionMailer::Base.deliveries.size }
    parent.reload.weekly_report_sent_on.should eq(week_start)
  end

  it "sends once a week however many times it runs" do
    answer(busy, week_start + 3)

    WeeklyReport.recipients(week_start).to_a.should eq([ parent ])
    expect { WeeklyReport.deliver(parent, week_start:) }.to change { ActionMailer::Base.deliveries.size }.by(1)
    WeeklyReport.recipients(week_start).should be_empty
  end

  it "only writes to parents who want it and whose address is confirmed" do
    unconfirmed = create(:user, role: :parent, verified_at: nil)
    stopped = create(:user, role: :parent, verified_at: Time.current, weekly_report: false)

    WeeklyReport.recipients(week_start).should include(parent)
    WeeklyReport.recipients(week_start).should_not include(unconfirmed, stopped)
  end

  it "writes the dates the way Bulgarian does" do
    I18n.with_locale(:bg) { WeeklyReport.new(parent, week_start:).dates_label.should eq("19–25 октомври") }
    I18n.with_locale(:bg) { WeeklyReport.new(parent, week_start: Date.new(2026, 9, 28)).dates_label.should eq("28 септември – 4 октомври") }
  end
end
