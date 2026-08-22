require "rails_helper"

describe "the performance trend on the student home page", type: :request do
  let(:student) { create(:user) }
  let(:assignment) { Assignment.create!(user: student) }

  def answer_weeks_ago(weeks, elo:)
    assignment_question = assignment.assignment_questions.create!(
      question: create(:question, elo:), position: assignment.assignment_questions.count + 1
    )
    UserAnswer.create!(
      user: student, assignment_question:, value: "42", correct: true,
      response: { "value" => "42" }, created_at: weeks.weeks.ago
    )
  end

  before { sign_in student }

  it "is not drawn until there are two weeks to draw a line between" do
    answer_weeks_ago(0, elo: 1200)

    get calendar_path

    response.body.should_not include(I18n.t("home.trend_sub"))
  end

  it "draws the chart once the student has two weeks of correct answers" do
    answer_weeks_ago(3, elo: 1000)
    answer_weeks_ago(0, elo: 1150)

    get calendar_path

    response.body.should include(I18n.t("home.trend_sub"))
    response.body.should include(I18n.t("home.trend_delta", delta: "+150"))
    # The line runs between the two weeks that have points, not across all nine.
    response.body.scan(/<polyline/).size.should eq(1)
  end
end
