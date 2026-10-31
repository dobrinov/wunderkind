require "rails_helper"

describe "Past papers", type: :request do
  before do
    stub_const("PastPapers::ROOT", Rails.root.join("spec/fixtures/past"))
    %w[Ред\ на\ действията Текстови\ задачи].each { |name| Topic.find_or_create_by!(name: name) }
    PastPapers.import_all
  end

  let(:student) { create(:user, elo: 1100) }

  it "lists a competition's papers and starts one as a timed paper" do
    sign_in student

    get competition_papers_path("sofiyski-matematicheski-turnir")
    response.body.should include("Минали теми", "Темата от 2024 · 3 клас", "2 задачи · 90 минути")

    expect { post competition_papers_path("sofiyski-matematicheski-turnir"), params: { grade: 3, year: 2024 } }
      .to change { student.assignments.mock.count }.by(1)
    assignment = student.assignments.mock.last
    [ assignment.paper_year, assignment.paper_grade ].should eq([ 2024, 3 ])
    response.should redirect_to(question_path(assignment.next_assignment_question))

    get question_path(assignment.next_assignment_question)
    response.body.should include("СМТ 2024 · 3 клас · задача 1")
  end

  it "offers „Минали теми“ beside the competition's practice" do
    sign_in student
    get competitions_path
    response.body.should include(competition_papers_path("sofiyski-matematicheski-turnir"))
  end
end
