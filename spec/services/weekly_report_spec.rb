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

  it "reports the week ending on the Sunday it runs, or the last full one on any other day" do
    WeeklyReport.week_start_for(Date.new(2026, 10, 25)).should eq(week_start) # that week's Sunday
    WeeklyReport.week_start_for(today).should eq(week_start) # a made-up run on the Monday after
    WeeklyReport.week_start_for(Date.new(2026, 11, 1)).should eq(Date.new(2026, 10, 26)) # the next Sunday
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

  it "names a quiet child beside a sibling who practised, and nobody when nobody did" do
    answer(busy, week_start + 1)
    answer(idle, week_start - 10)

    report = WeeklyReport.new(parent, week_start:)
    report.quiet_children.map { |quiet| [ quiet.child.name, quiet.days_since ] }.should eq([ [ "Боби", 16 ] ])

    WeeklyReport.new(parent, week_start: week_start - 28).quiet_children.should be_empty
  end

  it "labels the best week the child has had, and a week well under the last" do
    answer(busy, week_start - 7)
    2.times { answer(busy, week_start + 1) }
    WeeklyReport.new(parent, week_start:).children.first.label.should eq(:best)

    12.times { answer(idle, week_start - 6) }
    answer(idle, week_start + 2)
    WeeklyReport.new(parent, week_start:).children.find { |entry| entry.child == idle }.label.should eq(:quieter)
  end

  it "puts every reward still owed in the family first" do
    answer(busy, week_start + 1)
    goal = Goal.create!(child: busy, parent:, metric: :problems, mode: :total, period: :week, target: 1, reward: "кино", starts_on: week_start - 7)
    GoalAward.create!(goal:, period_start: week_start - 7, period_end: week_start - 1, reward: "кино", earned_at: week_start - 1)

    # Goals.refresh! may pay the week out too — every row is still „кино" for Ани.
    WeeklyReport.new(parent, week_start:).owed.map { |owed| [ owed.child.name, owed.reward ] }.uniq.should eq([ [ "Ани", "кино" ] ])
  end

  it "suggests a small goal for a slipping week, and nothing more once a goal runs" do
    [ -7, -6, -5 ].each { |offset| answer(busy, week_start + offset) }
    answer(busy, week_start + 1)
    WeeklyReport.new(parent, week_start:).children.first.suggestion.kind.should eq(:goal)

    Goal.create!(child: busy, parent:, metric: :minutes, mode: :daily, period: :week, target: 4, threshold: 10, reward: "кино", starts_on: week_start)
    WeeklyReport.new(parent, week_start:).children.first.suggestion.should be_nil
  end
end
