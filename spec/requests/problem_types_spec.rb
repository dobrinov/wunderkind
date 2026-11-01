require "rails_helper"

describe "Типови задачи", type: :request do
  before do
    stub_const("ProblemTypes::FILE", Rails.root.join("spec/fixtures/problem_types.yml"))
    ProblemTypes.instance_variable_set(:@all, nil)
  end
  after { ProblemTypes.instance_variable_set(:@all, nil) }

  let(:student) { create(:user, elo: 1100) }
  let!(:questions) do
    [ 900, 1000, 1100, 1200 ].map { |elo| create(:question, elo: elo, answer: "5", problem_type: "vazrastovi-zadachi") }
  end

  it "lists the types with enough problems, and only those" do
    create(:question, problem_type: "vezni") # one is not enough to offer
    sign_in student

    get problem_types_path
    response.body.should include("Възрастови задачи", "4 задачи")
    response.body.should_not include("Везни и равновесие")
  end

  it "practises one type at the child's level, easiest first" do
    other = create(:question, elo: 1100, answer: "5")
    sign_in student

    get problem_type_path("vazrastovi-zadachi")
    response.body.should include("Мама е на 32", "Реши 4 задачи")

    post problem_type_practice_path("vazrastovi-zadachi")
    assignment = student.assignments.last
    rows = assignment.assignment_questions.order(:position).map(&:question)
    rows.should_not include(other)
    rows.map(&:elo).should eq(rows.map(&:elo).sort)
    rows.map(&:problem_type).uniq.should eq([ "vazrastovi-zadachi" ])
  end

  # A strong student whose level the type never reaches gets its hardest
  # problems, not a random spread that „easiest first" opens on the 900s of.
  it "gives a student above the type its hardest problems" do
    Array.new(8) { |index| create(:question, elo: 910 + index, answer: "5", problem_type: "vazrastovi-zadachi") }
    hard = [ 1300, 1350, 1400, 1450 ].map { |elo| create(:question, elo: elo, answer: "5", problem_type: "vazrastovi-zadachi") }
    strong = create(:user, elo: 2500)
    sign_in strong

    post problem_type_practice_path("vazrastovi-zadachi")
    picked = strong.assignments.last.assignment_questions.map(&:question)
    picked.size.should eq(ProblemTypes::QUESTION_COUNT)
    picked.should include(*hard, *questions.last(3))
    picked.map(&:elo).min.should be >= 914
  end

  it "says where a type was set at a competition" do
    questions.first.update!(source: { "kind" => "original", "competition" => "sofiyski-matematicheski-turnir", "grade" => 3, "year" => 2019, "number" => "4" })
    sign_in student

    get problem_type_path("vazrastovi-zadachi")
    response.body.should include("Дадена на състезания", "СМТ 2019 · 3 клас · задача 4")
  end

  # One door on „Упражнения“, into the chooser whose second tab this is.
  it "is the second tab of the chooser „Упражнения“ opens" do
    sign_in student
    get practice_path
    response.body.should include(topic_practices_path, I18n.t("practice_chooser.title"))

    get topic_practices_path
    response.body.should include(problem_types_path, I18n.t("practice_chooser.types"))
  end
end
