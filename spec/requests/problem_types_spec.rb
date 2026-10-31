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

  it "says where a type was set at a competition" do
    questions.first.update!(source: { "kind" => "original", "competition" => "sofiyski-matematicheski-turnir", "grade" => 3, "year" => 2019, "number" => "4" })
    sign_in student

    get problem_type_path("vazrastovi-zadachi")
    response.body.should include("Дадена на състезания", "СМТ 2019 · 3 клас · задача 4")
  end

  it "is a page on „Упражнения“" do
    sign_in student
    get practice_path
    response.body.should include(problem_types_path, "Типови задачи")
  end
end
