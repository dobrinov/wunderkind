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
end
