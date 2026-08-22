require "rails_helper"

# The review of a past answer knows the same four outcomes the practice
# feedback card does. It used to branch only on correct?, so a skip and a
# pending free-text answer both reviewed as a red "wrong" with an empty answer.
describe "Reviewing a past answer", type: :request do
  let(:student) { create(:user, elo: 1200) }

  def assignment_question_for(question)
    assignment = Assignment.create!(user: student)
    assignment.assignment_questions.create!(question:, position: 1)
  end

  it "reviews a correct answer as correct" do
    assignment_question = assignment_question_for(create(:question, answer: "5"))

    sign_in student
    post "/questions/#{assignment_question.id}/answer", params: { value: "5" }
    get "/questions/#{assignment_question.id}/answer"

    response.body.should include(I18n.t("answers.correct"))
    response.body.should_not include(I18n.t("answers.correct_answer"))
  end

  it "reviews a skip as a skip, not as a wrong answer" do
    assignment_question = assignment_question_for(create(:question, answer: "5"))

    sign_in student
    post "/questions/#{assignment_question.id}/skip"
    get "/questions/#{assignment_question.id}/answer"

    response.should have_http_status(:ok)
    response.body.should include(I18n.t("answers.not_taught_recorded"))
    response.body.should_not include(I18n.t("answers.wrong"))
    # No answer was given, so none is shown — but the correct one is.
    response.body.should_not include(I18n.t("answers.your_answer"))
    response.body.should include(I18n.t("answers.correct_answer"))
  end

  it "reviews a pending free-text answer as waiting, keeping the rubric out" do
    question = create(:question, :free_text)
    assignment_question = assignment_question_for(question)

    sign_in student
    post "/questions/#{assignment_question.id}/answer", params: { value: "Защото са равни части." }
    get "/questions/#{assignment_question.id}/answer"

    response.should have_http_status(:ok)
    response.body.should include(I18n.t("free_text.pending"))
    response.body.should include("Защото са равни части.")
    response.body.should_not include(I18n.t("answers.wrong"))
    # The "correct answer" of a free-text question is the grading rubric —
    # the reviewer's to read, not the student's.
    response.body.should_not include(question.grading["rubric"])
  end
end
