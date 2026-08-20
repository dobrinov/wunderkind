require "rails_helper"

describe "Question preview", type: :request do
  let(:admin) { create(:user, role: :admin, verified_at: Time.current) }

  it "renders the student's view for every answer type without any way to answer" do
    questions = [
      create(:question),
      create(:question, :multiple_choice),
      create(:question, :interactive),
      create(:question, :free_text)
    ]

    sign_in admin

    questions.each do |question|
      get "/overseer/questions/#{question.id}/preview"

      response.should have_http_status(:ok)
      response.body.should include("question-body")
      # No form and no submit control: nothing on this page can be graded.
      response.body.should_not match(/<form/)
      response.body.should_not include('type="submit"')
      response.body.should_not include(question_answer_path(question))
    end
  end

  it "shows the correct answer and metadata only to the reviewer" do
    question = create(:question, answer: "42", explanation: "Защото е така.")

    sign_in admin
    get "/overseer/questions/#{question.id}/preview"

    response.body.should include("42")
    response.body.should include("Защото е така.")
    response.body.should include(I18n.t("preview.reviewer_only"))
  end

  it "reveals an approved hint ladder but not an unapproved one" do
    approved = create(:question)
    approved.create_hint!(ladder: [ "Първа подсказка" ], reviewed_at: Time.current)
    draft = create(:question)
    draft.create_hint!(ladder: [ "Чернова подсказка" ])

    sign_in admin

    get "/overseer/questions/#{approved.id}/preview"
    response.body.should include('data-controller="hints"')

    get "/overseer/questions/#{draft.id}/preview"
    # Still listed in the reviewer panel, but not offered as a student hint.
    response.body.should include("Чернова подсказка")
    response.body.should_not include('data-controller="hints"')
  end

  it "is closed to non-admins" do
    question = create(:question)

    sign_in create(:user)
    get "/overseer/questions/#{question.id}/preview"

    response.should redirect_to("/")
  end
end
