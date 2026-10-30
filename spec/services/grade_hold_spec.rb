require "rails_helper"

# Dispatcher.held_topic_ids: topics school has not reached for a child, held
# back from what the app picks on its own — see the comment there.
describe "Holding back topics school has not reached" do
  let(:first_grader) do
    # The school year that starts in September of the year the child turns seven.
    create(:user, elo: 800, birth_year: SchoolGrade.school_year_start(Time.zone.today) - 7)
  end
  let!(:addition) { Topic.create!(name: "Събиране и изваждане") }
  let!(:multiplication) { Topic.create!(name: "Умножение и деление") }
  let!(:fractions) { Topic.create!(name: "Дроби") }

  before do
    [ addition, multiplication, fractions ].each { |topic| create_list(:question, 6, elo: 800, topics: [ topic ]) }
  end

  def pool_topics(user, **options)
    Dispatcher.available_pool(user, **options).joins(:topics).distinct.pluck("topics.name")
  end

  it "holds fractions from a first-grader, and reaches one grade ahead" do
    first_grader.estimated_grade.should eq(1)
    pool_topics(first_grader).should contain_exactly("Събиране и изваждане", "Умножение и деление")
  end

  it "lets a topic the child has shown they can do back in" do
    assignment = Assignment.create!(user: first_grader)
    aq = assignment.assignment_questions.create!(question: fractions.questions.first, position: 1)
    AnswerSubmission.call(assignment_question: aq, user: first_grader, raw: { value: aq.question.grading["value"] || "1" })
    UserAnswer.where(user: first_grader).update_all(correct: true)

    pool_topics(first_grader).should include("Дроби")
  end

  it "gives a topic asked for by name — a focus, a competition — past the hold" do
    pool_topics(first_grader, allow: [ fractions.id ]).should include("Дроби")
    Dispatcher.pick(first_grader, count: 3, topic_ids: [ fractions.id ]).should_not be_empty
  end

  it "holds nothing for a child with no birth year" do
    pool_topics(create(:user, elo: 800)).should include("Дроби")
  end

  it "keeps a held topic off the frontier, so a daily session never names it" do
    first_grader.update!(placed_at: Time.current)
    SessionComposer.send(:frontier_topic_ids, first_grader).should_not include(fractions.id)
  end

  # A sibling duel in the family field test gave a 2nd-grader probability.
  it "holds the topics from a duel either player has not reached" do
    big_sister = create(:user, elo: 800)
    picked = Dispatcher.pick_shared([ first_grader, big_sister ], count: 6)

    picked.flat_map { |question| question.topics.map(&:name) }.should_not include("Дроби")
  end
end

describe "A duel between players far apart" do
  it "aims at the weaker player, and never two problems of one template" do
    young = create(:user, elo: 700)
    old = create(:user, elo: 1700)
    create_list(:question, 6, elo: 1200)
    easy = Array.new(6) { |index| create(:question, elo: 600, text: "Колко е #{index + 1} + #{index + 2}? Пример #{"абвгде"[index]}") }
    twins = Array.new(4) { |index| create(:question, elo: 620, text: "Кое число е точен квадрат: #{index + 10}?") }

    picked = Dispatcher.pick_shared([ young, old ], count: 5)

    picked.map(&:elo).max.should be < 1000
    (picked & twins).size.should be <= 1
    (picked & easy).size.should be >= 4
  end
end
