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
    create_list(:question, 8, elo: 1200)
    stretch = create(:question, elo: 1200 + SessionComposer::STRETCH_RANGE.min)

    assignment = SessionComposer.execute(user:, question_count: 6)

    assignment.questions.should include(stretch)
  end

  it "stretches within the student's own level, not into a higher grade" do
    create_list(:question, 8, elo: 1200)
    next_grade = create(:question, elo: 1200 + 300)

    assignment = SessionComposer.execute(user:, question_count: 6)

    assignment.questions.should_not include(next_grade)
  end

  it "never serves free-text questions in self-serve practice" do
    create_list(:question, 5, elo: 1200)
    free_text = create(:question, :free_text, elo: 1200)

    assignment = SessionComposer.execute(user:, question_count: 5)

    assignment.questions.should_not include(free_text)
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

    assignment = SessionComposer.execute(user: create(:user, elo: 1200), question_count: 10)
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
      to raise_error(AssignmentCreator::NotEnoughQuestions)
  end
end
