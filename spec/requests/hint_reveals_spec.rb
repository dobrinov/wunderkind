require "rails_helper"

describe "Revealing hints one rung at a time", type: :request do
  let(:student) { create(:user, elo: 1200) }
  let(:ladder) { [ "Първа стъпка", "Втора стъпка", "Трета стъпка" ] }
  let(:question) { create(:question, answer: "5") }
  let(:assignment) do
    Assignment.create!(user: student).tap do |a|
      a.assignment_questions.create!(question:, position: 1)
    end
  end
  let(:assignment_question) { assignment.assignment_questions.first }

  before do
    QuestionHint.create!(question:, ladder:, reviewed_at: Time.current)
  end

  it "keeps unrevealed rungs off the question page and serves them one per request" do
    sign_in student
    get "/questions/#{assignment_question.id}"

    response.body.should include(question_hint_reveal_path(assignment_question))
    ladder.each { |rung| response.body.should_not include(rung) }

    post "/questions/#{assignment_question.id}/hint"

    response.parsed_body.should eq({ "rung" => "Първа стъпка", "revealed" => 1, "total" => 3 })
    assignment_question.reload.hints_revealed.should eq(1)

    # A reload re-renders what was paid for — and nothing further.
    get "/questions/#{assignment_question.id}"
    response.body.should include("Първа стъпка")
    response.body.should_not include("Втора стъпка")
  end

  it "never counts past the ladder" do
    sign_in student
    4.times { post "/questions/#{assignment_question.id}/hint" }

    response.parsed_body["rung"].should eq("Трета стъпка")
    assignment_question.reload.hints_revealed.should eq(3)
  end

  it "halves the XP of the hinted answer without trusting anything from the client" do
    sign_in student
    post "/questions/#{assignment_question.id}/hint"
    # A forged hints_used field must change nothing — the count lives on the row.
    post "/questions/#{assignment_question.id}/answer", params: { value: "5", hints_used: 0 }

    assignment_question.reload.user_answer.response["hints_used"].should eq(1)
  end

  it "refuses once the question is answered" do
    sign_in student
    post "/questions/#{assignment_question.id}/answer", params: { value: "5" }
    post "/questions/#{assignment_question.id}/hint"

    response.should have_http_status(:conflict)
    assignment_question.reload.hints_revealed.should eq(0)
  end

  it "refuses when the session does not allow hints" do
    assignment.update!(hints_allowed: false)

    sign_in student
    post "/questions/#{assignment_question.id}/hint"

    response.should have_http_status(:not_found)
  end

  it "refuses an unreviewed ladder" do
    question.hint.update!(reviewed_at: nil)

    sign_in student
    post "/questions/#{assignment_question.id}/hint"

    response.should have_http_status(:not_found)
  end

  it "is scoped to the student's own assignment" do
    sign_in create(:user, elo: 1200)
    post "/questions/#{assignment_question.id}/hint"

    response.should have_http_status(:not_found)
  end
end
