require "rails_helper"

describe "A filled-in table, shown back to the child", type: :request do
  let(:student) { create(:user, elo: 1200, feedback_after_answer: true) }
  let(:question) do
    create(:question, answer_type: :interactive, grading: {
      "widget" => "grid_fill",
      "params" => { "rows" => [ [ 1, nil ], [ nil, 4 ] ], "column_headers" => [ "a", "b" ] },
      "solution" => { "cells" => { "0,1" => "2", "1,0" => "3" } }
    })
  end
  let(:assignment) { Assignment.create!(user: student, kind: :practice) }
  let!(:assignment_question) { assignment.assignment_questions.create!(question: question, position: 1) }

  before { sign_in student }

  it "draws the table with each cell marked, never the cells' coordinates" do
    post "/questions/#{assignment_question.id}/answer", params: { state: { cells: { "0,1" => "2", "1,0" => "9" } }.to_json }
    follow_redirect!

    response.body.should include(I18n.t("answers.grid_cells_right", right: 1, total: 2))
    response.body.should include("<table")
    response.body.should_not include("0,1:")
    response.body.should_not include("1,0:")
  end

  it "counts the right cells on the session's summary" do
    post "/questions/#{assignment_question.id}/answer", params: { state: { cells: { "0,1" => "2", "1,0" => "9" } }.to_json }
    get assignment_summary_path(assignment)

    response.body.should include(I18n.t("answers.grid_cells_right", right: 1, total: 2))
    response.body.should_not include("0,1:")
  end

  it "draws a pyramid the right way up, base last, with no table and none of its padding cells" do
    question.update!(grading: {
      "widget" => "grid_fill",
      "params" => { "layout" => "pyramid", "rows" => [ [ 2, nil ], [ 7, "" ] ] },
      "solution" => { "cells" => { "0,1" => "5" } }
    })
    post "/questions/#{assignment_question.id}/answer", params: { state: { cells: { "0,1" => "4" } }.to_json }
    follow_redirect!

    response.body.should include(I18n.t("answers.grid_cells_right", right: 0, total: 1))
    response.body.should_not include("<table")
    review = response.body[/flex-col items-center gap-1\.5.*/m]
    review.index(">7<").should be < review.index(">2<")
  end

  it "writes a table out as its numbers in reading order where it has to be one line" do
    Widgets.display("grid_fill", state: { "cells" => { "10,0" => "5", "2,1" => "8", "0,1" => "2" } }).should eq("2, 8, 5")
  end
end
