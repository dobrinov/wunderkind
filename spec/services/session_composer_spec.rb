require "rails_helper"

describe SessionComposer do
  let(:user) { create(:user, elo: 1200) }

  it "builds a session from the near-Elo pool when no adaptive signal exists" do
    create_list(:question, 10, elo: 1200)

    assignment = SessionComposer.execute(user:, question_count: 10)

    assignment.questions.count.should eq(10)
    assignment.assignment_questions.map(&:position).should eq((1..10).to_a)
  end

  it "prioritizes topics whose spaced review is due" do
    calibrated!(user)
    due_topic = Topic.create!(name: "Дроби")
    other_topic = Topic.create!(name: "Друго")
    due_question = create(:question, elo: 1200, topics: [ due_topic ])
    create_list(:question, 6, elo: 1200, topics: [ other_topic ])
    user.skills.create!(topic: due_topic, rating: 1200, review_due_at: 1.day.ago)

    assignment = SessionComposer.execute(user:, question_count: 5)

    assignment.questions.should include(due_question)
  end

  it "keeps locked topics out until their prerequisites are mastered" do
    basics = Topic.create!(name: "Събиране")
    advanced = Topic.create!(name: "Уравнения")
    TopicPrerequisite.create!(topic: advanced, prerequisite: basics)
    locked_question = create(:question, elo: 1200, topics: [ advanced ])
    create_list(:question, 5, elo: 1200, topics: [ basics ])

    assignment = SessionComposer.execute(user:, question_count: 3)
    assignment.questions.should_not include(locked_question)

    # Mastering the prerequisite unlocks the advanced topic for the frontier.
    user.skills.create!(topic: basics, rating: 1500, games_count: 20, mastered_at: Time.current)
    Question.where.not(id: locked_question.id).update_all(status: Question.statuses[:draft])
    create(:question, elo: 1200, topics: [ advanced ]) # ensure enough supply
    assignment = SessionComposer.execute(user:, question_count: 2)
    assignment.questions.should include(locked_question)
  end

  it "includes a stretch question in larger sessions when available" do
    calibrated!(user)
    create_list(:question, 8, elo: 1200)
    stretch = create(:question, elo: 1200 + SessionComposer::STRETCH_RANGE.min)

    assignment = SessionComposer.execute(user:, question_count: 6)

    assignment.questions.should include(stretch)
  end

  # Once the student has a rating we trust, the stretch reaches a little past
  # them — not into material a long way beyond what the session is asking.
  it "keeps the stretch within reach of the student's own rating" do
    calibrated!(user)
    create_list(:question, 8, elo: 1200)
    far_harder = create(:question, elo: 1200 + 300)

    assignment = SessionComposer.execute(user:, question_count: 6)

    assignment.questions.should_not include(far_harder)
  end

  it "never serves free-text questions in self-serve practice" do
    create_list(:question, 5, elo: 1200)
    free_text = create(:question, :free_text, elo: 1200)

    assignment = SessionComposer.execute(user:, question_count: 5)

    assignment.questions.should_not include(free_text)
  end

  it "climbs a ladder of difficulties for a student with no history to read" do
    (600..1600).step(100) { |elo| create_list(:question, 3, elo:) }

    assignment = SessionComposer.execute(user: create(:user, elo: 700), question_count: 6)
    elos = assignment.questions.map(&:elo).sort

    # The whole point of calibration: one session spans the range rather than
    # sitting in a band, so wherever the student stops getting them right is
    # their level.
    (elos.last - elos.first).should be >= Dispatcher::CALIBRATION_CLIMB / 2
  end

  it "stops laddering and settles into a band once the rating is trusted" do
    (600..1600).step(100) { |elo| create_list(:question, 3, elo:) }
    user = calibrated!(create(:user, elo: 1200))

    assignment = SessionComposer.execute(user:, question_count: 6)
    elos = assignment.questions.map(&:elo)

    elos.max.should be <= 1200 + SessionComposer::STRETCH_RANGE.max
  end

  it "does not lock a new student out of topics they have outgrown" do
    # A fresh student has mastered nothing on record, but their rating shows
    # they are well past the prerequisite's level.
    basics = Topic.create!(name: "Събиране")
    advanced = Topic.create!(name: "Дроби")
    TopicPrerequisite.create!(topic: advanced, prerequisite: basics)
    create_list(:question, 3, elo: 700, topics: [ basics ])
    advanced_questions = create_list(:question, 6, elo: 1200, topics: [ advanced ])

    strong = create(:user, elo: 1200)
    assignment = SessionComposer.execute(user: strong, question_count: 5)

    (assignment.questions.to_a & advanced_questions).should_not be_empty
  end

  it "spreads a session across topics instead of filling it from one" do
    topics = 4.times.map { |i| Topic.create!(name: "Тема #{i}") }
    topics.each { |topic| create_list(:question, 10, elo: 1200, topics: [ topic ]) }

    assignment = SessionComposer.execute(user: calibrated!(create(:user, elo: 1200)), question_count: 10)
    per_topic = assignment.questions.flat_map { |q| q.topics.map(&:name) }.tally

    per_topic.values.max.should be <= SessionComposer::MAX_PER_TOPIC
  end

  # The arithmetic fact tables put thousands of "a + b" drills in one topic, so
  # a near-Elo pool can be almost entirely one template.
  it "caps how many problems of one template a session may contain" do
    40.times { |i| create(:question, elo: 1200, text: "Колко е #{i} + #{i + 1}?") }
    [ "Кое число е просто?", "Колко градуса е сумата на ъглите?", "Коя дроб е по-голяма?",
      "Колко е периметърът на квадрата?", "Кой е най-малкият делител?", "По колко начина?",
      "Какъв е остатъкът?", "Кое число е най-голямо?", "Колко е обемът на куба?",
      "Каква част от басейна?" ].each { |text| create(:question, elo: 1200, text: text) }

    assignment = SessionComposer.execute(user:, question_count: 10)
    per_shape = assignment.questions.group_by { |q| ProblemSeeds.shape_of(q.body_text) }.transform_values(&:size)

    assignment.questions.count.should eq(10)
    per_shape.values.max.should be <= SessionComposer::MAX_PER_SHAPE
  end

  # A full session beats a varied one: the cap yields when there is nothing else
  # to put in the slot.
  it "still fills the session when every problem shares one template" do
    20.times { |i| create(:question, elo: 1200, text: "Колко е #{i} + #{i + 1}?") }

    assignment = SessionComposer.execute(user:, question_count: 10)

    assignment.questions.count.should eq(10)
  end

  it "varies between sessions for the same student" do
    create_list(:question, 60, elo: 1200)
    user = create(:user, elo: 1200)

    first = SessionComposer.execute(user: user, question_count: 10).questions.map(&:id).sort
    second = SessionComposer.execute(user: user, question_count: 10).questions.map(&:id).sort

    first.should_not eq(second)
  end

  it "raises when the pool is too small" do
    create(:question, elo: 1200)

    expect { SessionComposer.execute(user:, question_count: 5) }.
      to raise_error(Dispatcher::NotEnoughQuestions)
  end
end

describe SessionComposer, "deferred topics" do
  let(:user) { create(:user, elo: 1200) }
  let(:skipped_topic) { Topic.create!(name: "Проценти") }
  let(:other_topic) { Topic.create!(name: "Събиране") }

  it "keeps a deferred topic out of the session while other material exists" do
    3.times { create(:question, elo: 1200, topics: [ skipped_topic ]) }
    3.times { create(:question, elo: 1200, topics: [ other_topic ]) }
    user.skill_for(skipped_topic).update!(deferred_until: 3.weeks.from_now)

    assignment = SessionComposer.execute(user:, question_count: 3)

    assignment.questions.flat_map(&:topics).uniq.should eq([ other_topic ])
  end

  it "falls back to deferred material rather than failing to build a session" do
    3.times { create(:question, elo: 1200, topics: [ skipped_topic ]) }
    user.skill_for(skipped_topic).update!(deferred_until: 3.weeks.from_now)

    assignment = SessionComposer.execute(user:, question_count: 3)

    assignment.questions.count.should eq(3)
  end
end
