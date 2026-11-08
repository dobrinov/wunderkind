require "rails_helper"

describe "An operation chain, shown back to the child", type: :request do
  let(:student) { create(:user, elo: 1200, feedback_after_answer: true) }
  let(:question) do
    create(:question, answer_type: :interactive, grading: {
      "widget" => "operation_chain",
      "params" => { "chains" => [ { "tiles" => [ 2, 3, 4 ], "ops" => [ "+", "−" ],
                                     "cells" => { "tl" => nil, "tr" => 2, "m" => nil, "r" => nil, "b" => 1 } } ] },
      "solution" => { "values" => { "0.tl" => "2", "0.m" => "4", "0.r" => "3" } }
    })
  end
  let(:assignment) { Assignment.create!(user: student, kind: :practice) }
  let!(:assignment_question) { assignment.assignment_questions.create!(question: question, position: 1) }

  before { sign_in student }

  it "draws the chain with each square marked, never the answer as one line" do
    post "/questions/#{assignment_question.id}/answer", params: { state: { values: { "0.tl" => "2", "0.m" => "4", "0.r" => "2" } }.to_json }
    follow_redirect!

    response.body.should include(I18n.t("answers.grid_cells_right", right: 2, total: 3))
    response.body.should include("line-through")
    response.body.should_not include("2, 2, 4, 2, 1")
  end

  it "draws the corrected chain solved inside a report's thread" do
    report = QuestionReport.file!(question: question, user: student, reason: :misleading)
    report.team_reply!(by: create(:user, role: :admin), body: "Готово!", corrected_question: question)

    get "/reports/#{report.id}"

    response.body.should include("chain-review-#{question.id}-0")
    response.body.should_not include("2, 2, 4, 3, 1")
  end
end
