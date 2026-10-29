require "rails_helper"

describe "„Упражнения“ — every way to practise", type: :request do
  let(:student) { create(:user, daily_minutes_target: 15) }

  it "leads with today's session and offers the review list and competitions" do
    sign_in student
    get practice_path

    response.should have_http_status(:ok)
    response.body.should include(daily_assignment_path, I18n.t("practice_page.daily_sub", count: 15))
    response.body.should include(review_path, I18n.t("review.empty_wrong"))
    response.body.should include(competitions_path)
  end

  it "counts the mistakes waiting for another try" do
    question = create(:question, answer: "5")
    assignment = Assignment.create!(user: student)
    assignment_question = assignment.assignment_questions.create!(question:, position: 1)
    AnswerSubmission.call(assignment_question:, user: student, raw: { value: "4" })

    sign_in student
    get practice_path

    response.body.should include(I18n.t("practice_page.review_sub", count: 1))
  end

  it "is a student's page" do
    sign_in create(:user, role: :parent)
    get practice_path

    response.should redirect_to(parents_children_path)
  end
end
