require "rails_helper"

RSpec.describe CompetitionPractice do
  let(:logic) { Topic.create!(name: "Логически задачи", parent: Topic.create!(name: "Логика")) }
  let(:arithmetic) { Topic.create!(name: "Събиране и изваждане", parent: Topic.create!(name: "Аритметика")) }
  let(:student) { create(:user, elo: 1200, placed_at: Time.current) }
  let(:event) { competition_event(topics: [ "Логически задачи" ]) }

  def publish(topic, count, elo:, text: nil)
    Array.new(count) do |index|
      create(:question, elo: elo + index, text: text || "Задача номер #{index} за #{topic.name} #{SecureRandom.hex(3)}").tap { |question| question.topics << topic }
    end
  end

  it "builds a competition session from the event's topics only" do
    on_topic = publish(logic, 15, elo: 1150)
    publish(arithmetic, 15, elo: 1150)

    assignment = CompetitionPractice.execute(user: student, event: event)

    expect(assignment).to be_competition
    expect(assignment.competition_slug).to eq(event.slug)
    expect(assignment.questions.size).to eq(CompetitionPractice::QUESTION_COUNT)
    expect(assignment.questions).to all(be_in(on_topic))
  end

  it "aims above the student's everyday target" do
    publish(logic, 10, elo: Dispatcher.target_rating(student.elo) - 300)
    harder = publish(logic, 10, elo: Dispatcher.target_rating(student.elo) + CompetitionPractice::LIFT)

    assignment = CompetitionPractice.execute(user: student, event: event)

    expect(assignment.questions).to all(be_in(harder))
  end

  it "keeps any one template to the session cap" do
    publish(logic, 12, elo: 1150, text: "Колко са 3 ябълки и 4 круши?")
    publish(logic, 12, elo: 1150)

    shapes = CompetitionPractice.execute(user: student, event: event).questions.map { |question| ProblemSeeds.shape_of(question.body_text) }

    expect(shapes.tally.values.max).to be <= SessionComposer::MAX_PER_SHAPE
  end

  it "is measured, like any other session of fresh problems" do
    publish(logic, 10, elo: 1150)

    expect(CompetitionPractice.execute(user: student, event: event)).to be_measured
  end

  it "refuses rather than padding with other topics when there is nothing on the event's" do
    publish(arithmetic, 15, elo: 1150)

    expect { CompetitionPractice.execute(user: student, event: event) }.to raise_error(CompetitionPractice::NothingToPractise)
  end
end
