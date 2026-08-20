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

  it "raises when the pool is too small" do
    create(:question, elo: 1200)

    expect { SessionComposer.execute(user:, question_count: 5) }.
      to raise_error(AssignmentCreator::NotEnoughQuestions)
  end
end
