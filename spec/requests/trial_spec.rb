require "rails_helper"

# „Опитай без профил": a few real problems for a visitor, kept in the session,
# graded by the real Grading, and ending at the sign-up. What matters is that
# it works without an account, writes nothing, and gets to the end.
RSpec.describe "Trial without an account", type: :request do
  let!(:topic) { Topic.create!(name: "Умножение и деление", parent: Topic.create!(name: "Аритметика")) }

  # Third grade's window is 850...1150: one problem per fifth of it.
  let!(:questions) do
    [ 860, 920, 980, 1040, 1100 ].map do |elo|
      create(:question, elo: elo, answer: "12", explanation: "3 · 4 = 12").tap { |question| question.topics << topic }
    end
  end

  it "offers every grade" do
    get "/opitay"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(trial_grade_path("1-klas"), trial_grade_path("12-klas"))
  end

  it "deals the grade's problems easy to hard and opens the first" do
    get "/opitay/3-klas"

    expect(session[:trial]["ids"]).to eq(questions.map(&:id))
    expect(response).to redirect_to(trial_question_path("3-klas", 1))

    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("trial.show.footnote"))
  end

  it "leaves out problems without an explanation, from another grade's programme, or with a drawn answer" do
    questions.each { |question| question.update!(status: :draft) }
    create(:question, elo: 900, explanation: "").topics << topic
    create(:question, elo: 900, explanation: "x").topics << Topic.create!(name: "Логаритмична функция", parent: topic.parent)
    create(:question, :interactive, elo: 900, explanation: "x",
                      grading: { "widget" => "grid_fill", "params" => {}, "solution" => { "cells" => {} } }).topics << topic

    get "/opitay/3-klas"

    expect(response).to redirect_to(trial_path)
  end

  it "grades an answer, shows the explanation, and records nothing" do
    get "/opitay/3-klas"

    expect {
      post trial_question_path("3-klas", 1), params: { value: "11" }
    }.not_to change { [ UserAnswer.count, User.count, questions.first.reload.elo ] }

    follow_redirect!
    expect(response.body).to include(I18n.t("practice.wrong_title"), "3 · 4 = 12")
    expect(session[:trial]["answers"]["1"]).to eq("correct" => false, "value" => "11")
  end

  it "keeps the first answer to a problem" do
    get "/opitay/3-klas"
    post trial_question_path("3-klas", 1), params: { value: "12" }
    post trial_question_path("3-klas", 1), params: { value: "11" }

    expect(session[:trial]["answers"]["1"]["correct"]).to be(true)
  end

  it "sends an empty answer back to the problem" do
    get "/opitay/3-klas"
    post trial_question_path("3-klas", 1), params: { value: " " }

    expect(response).to redirect_to(trial_question_path("3-klas", 1))
    expect(session[:trial]["answers"]).to be_empty
  end

  it "ends on the score and the sign-up, and deals a new set after" do
    get "/opitay/3-klas"
    get trial_result_path("3-klas")
    expect(response).to redirect_to(trial_question_path("3-klas", 1))

    (1..Trial::LENGTH).each { |position| post trial_question_path("3-klas", position), params: { value: "12" } }
    expect(flash[:analytics]["name"]).to eq("Trial Finished")

    get trial_result_path("3-klas")
    expect(response.body).to include(I18n.t("trial.result.title", correct: 5, total: 5), sign_up_path)

    get "/opitay/3-klas"
    expect(session[:trial]["answers"]).to be_empty
  end

  it "starts a set for a link into the middle of one this browser never began" do
    get trial_question_path("3-klas", 3)

    expect(response).to redirect_to(trial_grade_path("3-klas"))
  end

  it "sends a signed-in user to their own page" do
    user = create(:user)
    sign_in user

    get "/opitay"

    expect(response).to be_redirect
    expect(response.location).not_to include("/opitay")
  end

  it "is linked from the landing page and from the grade pages" do
    get root_path
    expect(response.body).to include(%(href="#{trial_path}"))

    get "/matematika/3-klas"
    expect(response.body).to include(trial_grade_path("3-klas"))
  end
end
