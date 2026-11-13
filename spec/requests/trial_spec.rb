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
    expect(response.body).to include(trial_deck_path("1-klas"), trial_deck_path("12-klas"))
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

    expect(response).to redirect_to(trial_deck_path("3-klas"))
  end

  it "sends a signed-in user to their own page" do
    user = create(:user)
    sign_in user

    get "/opitay"

    expect(response).to be_redirect
    expect(response.location).not_to include("/opitay")
  end

  it "is linked from the landing page, the grade pages and the topic pages" do
    get root_path
    expect(response.body).to include(%(href="#{trial_path}"))

    get "/matematika/3-klas"
    expect(response.body).to include(trial_deck_path("3-klas"))

    get curriculum_topic_path(topic.slug)
    expect(response.body).to include(trial_deck_path("tema-#{topic.slug}"))
  end

  it "deals a topic's problems on its own" do
    get trial_deck_path("tema-#{topic.slug}")

    expect(session[:trial]["ids"]).to match_array(questions.map(&:id))
  end

  it "goes straight in when a competition's papers are for one grade only" do
    stub_calendar(competition_event(slug: "test-nvo", short: "НВО", grades: [ 4, 4 ], topics: [ topic.name ]))
    Trial::LENGTH.times do |index|
      create(:question, elo: 1000 + index, explanation: "Решение",
                        source: { "kind" => "original", "competition" => "test-nvo", "grade" => 4, "year" => 2024, "number" => index.to_s })
    end

    get trial_deck_path("test-nvo")

    expect(response).to redirect_to(trial_deck_path("test-nvo-4-klas"))
  end

  it "draws each problem from a topic the set has not had where it can" do
    others = %w[Дроби Периметър Ъгли Площ].map { |name| Topic.create!(name: name, parent: topic.parent) }
    # A second problem of the first topic in every slice, next to one of a new topic.
    questions.drop(1).zip(others).each do |question, other|
      create(:question, elo: question.elo, explanation: "x").topics << topic
      question.topics.replace([ other ])
    end
    Curriculum::PROGRAMME[3].then { |names| stub_const("Curriculum::PROGRAMME", Curriculum::PROGRAMME.merge(3 => names + others.map(&:name))) }

    get "/opitay/3-klas"

    picked = Question.find(session[:trial]["ids"]).flat_map(&:topic_ids)
    expect(picked).to match_array([ topic, *others ].map(&:id))
  end

  describe "a competition" do
    let(:smt) { competition_event(slug: "test-smt", short: "СМТ", grades: [ 1, 4 ], topics: [ topic.name ]) }

    before { stub_calendar(smt) }

    # The paper's own problems, and the ones written on their model.
    def paper_problems(grade:, count: Trial::LENGTH)
      Array.new(count) do |index|
        create(:question, elo: 1000 + index * 40, explanation: "Решение",
                          source: { "kind" => index.even? ? "original" : "modelled", "competition" => "test-smt",
                                    "grade" => grade, "year" => 2024, "number" => (index + 1).to_s })
      end
    end

    it "with papers in the bank asks for the grade, then deals that grade's own problems" do
      third = paper_problems(grade: 3)
      paper_problems(grade: 4)
      paper_problems(grade: 2, count: 2) # too few to offer

      get trial_deck_path("test-smt")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(trial_deck_path("test-smt-3-klas"), trial_deck_path("test-smt-4-klas"))
      expect(response.body).not_to include(trial_deck_path("test-smt-2-klas"))

      get trial_deck_path("test-smt-3-klas")
      expect(session[:trial]["ids"]).to eq(third.map(&:id))
      expect(flash[:analytics]["props"]).to include("kind" => "competition", "competition" => "test-smt", "grade" => "3")

      follow_redirect!
      expect(response.body).to include("СМТ 2024")
    end

    it "without papers deals from its topics in its grades" do
      get trial_deck_path("test-smt")

      expect(session[:trial]["ids"]).to match_array(questions.map(&:id))
    end

    it "is offered on the competition's page, per grade of its papers too, and its sign-up enters it" do
      paper_problems(grade: 3)

      get competition_page_path("test-smt")
      expect(response.body).to include(trial_deck_path("test-smt"), trial_deck_path("test-smt-3-klas"))

      get trial_deck_path("test-smt-3-klas")
      (1..Trial::LENGTH).each { |position| post trial_question_path("test-smt-3-klas", position), params: { value: "42" } }
      get trial_result_path("test-smt-3-klas")
      expect(response.body).to include(sign_up_path(competition: "test-smt"))
    end
  end

  it "refuses a deck that names nothing" do
    get "/opitay/nyama-takova"

    expect(response).to have_http_status(:not_found)
  end
end
