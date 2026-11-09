require "rails_helper"

describe "A box diagram", type: :request do
  let(:student) { create(:user, elo: 1200, feedback_after_answer: true) }
  let(:params) do
    { "width" => 5, "height" => 4,
      "boxes" => [ { "id" => "a", "x" => 0.5, "y" => 0.3, "name" => "А" }, { "id" => "s", "x" => 3, "y" => 0.3, "text" => "8 − 1" },
                   { "id" => "b", "x" => 2, "y" => 2.5, "name" => "Б" } ],
      "arrows" => [ [ [ 1, 1.3 ], [ 2.3, 2.45 ] ], [ [ 3.5, 1.3 ], [ 2.7, 2.45 ] ] ],
      "labels" => [ { "text" => "= ? + ?", "x" => 4, "y" => 3 } ] }
  end
  let(:question) do
    create(:question, answer_type: :interactive, grading: {
      "widget" => "box_diagram", "params" => params, "solution" => { "values" => { "a" => "2", "b" => "9" } }
    })
  end
  let(:assignment) { Assignment.create!(user: student, kind: :practice) }
  let!(:assignment_question) { assignment.assignment_questions.create!(question: question, position: 1) }

  before { sign_in student }

  it "puts an answer box on every empty square of the picture, and none on a given one" do
    get "/questions/#{assignment_question.id}"

    response.should have_http_status(:ok)
    response.body.should include('data-controller="widget-box-diagram"')
    response.body.scan('data-widget-box-diagram-target="box"').size.should eq(2)
    response.body.should include("8 − 1")
    response.body.should include("= ? + ?")
    response.body.should_not include('"values"')
  end

  it "draws the diagram back with each box marked, never the answer as one line" do
    post "/questions/#{assignment_question.id}/answer", params: { state: { values: { "a" => "2", "b" => "8" } }.to_json }
    follow_redirect!

    response.body.should include(I18n.t("answers.grid_cells_right", right: 1, total: 2))
    response.body.should include("line-through")
    response.body.should_not include("А = 2, Б = 8")
  end

  it "grades a full and right diagram as right" do
    post "/questions/#{assignment_question.id}/answer", params: { state: { values: { "a" => "2", "b" => "9" } }.to_json }

    student.user_answers.last.should be_correct
  end

  it "draws the corrected diagram solved inside a report's thread" do
    report = QuestionReport.file!(question: question, user: student, reason: :misleading)
    report.team_reply!(by: create(:user, role: :admin), body: "Готово!", corrected_question: question)

    get "/reports/#{report.id}"

    response.body.should include("box-diagram-review-#{question.id}")
    response.body.should_not include("А = 2, Б = 9")
  end

  it "is on the design system" do
    allow(Rails.env).to receive(:development?).and_return(true)

    get "/design-system"

    response.should have_http_status(:ok)
    response.body.should include('data-controller="widget-box-diagram"')
  end
end
