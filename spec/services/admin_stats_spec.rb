require "rails_helper"

describe AdminStats do
  # A Wednesday, so the cohort weeks fall on known Mondays.
  let(:today) { Date.new(2026, 10, 28) }
  let(:fractions) { Topic.create!(name: "Дроби") }
  let(:sums) { Topic.create!(name: "Събиране") }

  around { |example| travel_to(today.noon) { example.run } }

  def answer(user, days_ago:, correct: false, skipped: false, topic: sums, question: nil, duration_ms: 60_000)
    assignment = Assignment.create!(user:)
    question ||= create(:question).tap { |q| q.topics << topic }
    UserAnswer.create!(
      user:, assignment_question: assignment.assignment_questions.create!(question:, position: 1),
      value: "42", correct:, skipped:, response: { "value" => "42" },
      duration_ms: skipped ? nil : duration_ms, created_at: (today - days_ago).noon
    )
  end

  def session(user, finished: true, kind: :practice, abandoned: false)
    Assignment.create!(user:, kind:, completed_at: (Time.current if finished), abandoned_at: (Time.current if abandoned))
  end

  def stats(days: 7, user_ids: nil) = AdminStats.new(days:, user_ids:, today:)

  let(:mimi) { create(:user, created_at: 60.days.ago) }
  let(:niki) { create(:user, created_at: 60.days.ago) }
  let(:admin) { create(:user, role: :admin) }

  describe "the headlines" do
    before do
      answer(mimi, days_ago: 0, correct: true)
      answer(mimi, days_ago: 1, correct: true)
      answer(mimi, days_ago: 2)
      answer(mimi, days_ago: 2, skipped: true)
      answer(niki, days_ago: 9, correct: true)
      # The owner testing: in no number.
      5.times { answer(admin, days_ago: 0, correct: true) }
    end

    it "compares the range with the same length before it, admins left out" do
      s = stats
      s.problems.to_a.should eq([ 3, 1 ])
      s.problems.change.should eq(200)
      s.minutes.to_a.should eq([ 3, 1 ])
      s.correct_share.current.should be_within(0.1).of(66.7)
      s.correct_share.points.should eq(-33.3)
      s.skip_share.to_a.should eq([ 25.0, 0.0 ])
      s.active_per_week.to_a.should eq([ 1, 1 ])
      s.target_share.should eq(70)
    end

    it "narrows to a set of users" do
      s = stats(user_ids: [ niki.id ])
      s.problems.to_a.should eq([ 0, 1 ])
      s.problems.change.should eq(-100)
      s.active_per_week.to_a.should eq([ 0, 1 ])
      s.student_funnel.should be_nil
      s.cohorts.should be_nil
    end

    it "averages active students over the range's whole weeks" do
      answer(niki, days_ago: 20, correct: true)
      # 30 days is four weeks: Mimi in week 0, Niki in weeks 1 and 2.
      stats(days: 30).active_per_week.current.should eq(1) # (1 + 1 + 1 + 0) / 4 = 0.75
    end
  end

  it "follows new students and new parents through their first days, nested" do
    placed_twice = create(:user, created_at: 3.days.ago, placed_at: 3.days.ago)
    2.times { session(placed_twice) }
    session(placed_twice, kind: :placement)
    placed_once = create(:user, created_at: 2.days.ago, placed_at: 2.days.ago)
    session(placed_once)
    session(placed_once, abandoned: true)
    unplaced = create(:user, created_at: 2.days.ago)
    session(unplaced)
    create(:user, created_at: 1.day.ago)
    create(:user, created_at: 1.day.ago, role: :admin)
    create(:user, created_at: 20.days.ago, placed_at: 20.days.ago) # before the range

    stats.student_funnel.steps.to_h.should eq(signed_up: 4, placed: 2, first_session: 2, two_sessions: 1)

    handing = create(:user, role: :parent, created_at: 2.days.ago)
    child = User.create_managed_child!(parent: handing, name: "Ани")
    child.update_columns(last_login_at: 1.day.ago, created_at: 30.days.ago)
    session(child)
    linking = create(:user, role: :parent, created_at: 2.days.ago)
    linking.parent_links.create!(child: create(:user, created_at: 30.days.ago))
    create(:user, role: :parent, created_at: 1.day.ago)

    funnel = stats.parent_funnel
    funnel.steps.to_h.should eq(signed_up: 3, child_added: 2, handed_over: 1, child_practised: 1)
    funnel.share(2).should eq(67)
  end

  it "counts who comes back by sign-up week, leaving weeks not yet over empty" do
    # Cohort weeks run from Monday 14 September, six of them.
    back = create(:user, created_at: Time.zone.local(2026, 9, 15, 10))
    create(:user, created_at: Time.zone.local(2026, 9, 17, 10))
    answer(back, days_ago: (today - Date.new(2026, 9, 23)).to_i, correct: true) # day 8: week 1
    answer(back, days_ago: (today - Date.new(2026, 9, 30)).to_i, skipped: true) # a skip is not coming back
    answer(back, days_ago: (today - Date.new(2026, 10, 1)).to_i, correct: true) # day 16: week 2

    cohorts = stats.cohorts
    cohorts.size.should eq(6)
    cohorts.first.week.should eq(Date.new(2026, 9, 14))
    cohorts.first.size.should eq(2)
    cohorts.first.weeks.should eq([ 50, 50, 0, 0, nil, nil ])
    cohorts.last.weeks.should all(be_nil)
  end

  it "ranks topics by skip share among those with enough answers" do
    stub_const("AdminStats::MIN_TOPIC_ANSWERS", 3)
    2.times { answer(mimi, days_ago: 1, topic: fractions, skipped: true) }
    answer(mimi, days_ago: 1, topic: fractions)
    answer(mimi, days_ago: 1, topic: sums, skipped: true)
    3.times { answer(mimi, days_ago: 1, topic: sums) }
    answer(admin, days_ago: 1, topic: fractions, skipped: true)

    stats.skip_topics.map { |topic| [ topic.name, topic.skipped, topic.answers ] }.
      should eq([ [ "Дроби", 2, 3 ], [ "Събиране", 1, 4 ] ])
  end

  it "reads the bank: questions shown, created and suggested" do
    question = create(:question, created_at: 30.days.ago)
    answer(mimi, days_ago: 1, question:)
    answer(niki, days_ago: 1, question:, skipped: true)
    create(:question, status: :published, suggested_by: mimi)
    create(:question, status: :in_review, suggested_by: niki)
    create(:question, status: :published, suggested_by: admin)

    s = stats
    s.questions_seen.should eq(1)
    s.published_bank.should eq(3)
    s.questions_created.should eq(3)
    s.suggestions.should eq([ 2, 1 ])
  end

  it "counts duels, invitations, rooms that never started and the median wait" do
    room = ->(**attrs) { Challenge.create!(question_count: 5, seconds_per_question: 30, target_elo: 1000, **attrs) }
    finished = room.(status: :finished, finished_at: 1.day.ago, created_at: 1.day.ago - 40.seconds,
                     paired_at: 1.day.ago - 30.seconds)
    finished.participants.create!(user: mimi)
    room.(status: :finished, finished_at: 1.day.ago, invited_user: niki)
    room.(status: :abandoned, created_at: 2.days.ago)
    room.(status: :lobby, created_at: 1.day.ago - 20.seconds, paired_at: 1.day.ago)
    room.(status: :finished, finished_at: 20.days.ago)
    with_admin = room.(status: :finished, finished_at: 1.day.ago)
    with_admin.participants.create!(user: admin)

    stats.duels.should eq(finished: 2, invited: 1, opened: 5, unplayed: 1)
    stats.median_wait.should eq(15)
    stats(user_ids: [ mimi.id ]).duels[:finished].should eq(1)
  end
end
