require "rails_helper"

describe "Skipping a question", type: :request do
  let(:student) { create(:user, elo: 1200) }

  def assignment_with(count)
    assignment = Assignment.create!(user: student)
    count.times { |index| assignment.assignment_questions.create!(question: create(:question, answer: "5"), position: index + 1) }
    assignment
  end

  it "offers the shrug button on an unanswered question" do
    assignment_question = assignment_with(2).assignment_questions.first

    sign_in student
    get "/questions/#{assignment_question.id}"

    response.should have_http_status(:ok)
    response.body.should include(question_skip_path(assignment_question))
    response.body.should include(I18n.t("answers.not_taught"))
    response.body.should include(I18n.t("answers.not_taught_tooltip"))
  end

  it "records the skip and moves on" do
    assignment = assignment_with(2)
    assignment_question = assignment.assignment_questions.first

    sign_in student
    post "/questions/#{assignment_question.id}/skip"

    response.should redirect_to(question_path(assignment.assignment_questions.second))
    assignment_question.reload.user_answer.should be_skipped
  end

  it "shows the neutral feedback and the solution when feedback is on" do
    student.update!(feedback_after_answer: true)
    assignment = assignment_with(2)
    assignment_question = assignment.assignment_questions.first

    sign_in student
    post "/questions/#{assignment_question.id}/skip"
    follow_redirect!

    response.body.should include(I18n.t("answers.not_taught_recorded"))
    response.body.should include(I18n.t("answers.correct_answer"))
    response.body.should_not include(I18n.t("answers.wrong"))
  end

  it "refuses to let another student's question be skipped" do
    assignment_question = assignment_with(1).assignment_questions.first

    sign_in create(:user)
    post "/questions/#{assignment_question.id}/skip"

    response.should have_http_status(:not_found)
    assignment_question.reload.user_answer.should be_nil
  end

  it "keeps the skip out of the summary score" do
    assignment = assignment_with(2)

    sign_in student
    post "/questions/#{assignment.assignment_questions.first.id}/answer", params: { value: "5" }
    post "/questions/#{assignment.assignment_questions.second.id}/skip"
    follow_redirect!

    response.body.should include(I18n.t("summary.score", percentage: 100))
    response.body.should include(I18n.t("summary.skipped", count: 1))
  end
end
