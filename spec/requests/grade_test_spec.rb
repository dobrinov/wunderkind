require "rails_helper"

# A grade's test (/matematika/3-klas/test): a paper on one page, marked by the
# real Grading when it is handed in, with nothing stored.
RSpec.describe "A grade's test", type: :request do
  let!(:topic) { Topic.create!(name: "Умножение и деление", parent: Topic.create!(name: "Аритметика")) }

  before do
    30.times do |index|
      create(:question, status: :published, elo: 860 + index * 9, answer: "24", explanation: "6 · 4 = 24").topics << topic
    end
    10.times do |index|
      create(:question, :multiple_choice, status: :published, elo: 865 + index * 27, answer: "7", explanation: "56 : 8 = 7").topics << topic
    end
  end

  def test_questions = Curriculum.test_questions(Curriculum.grade("3-klas"))

  it "sets ten problems that are not the grade page's samples" do
    samples = Curriculum.sample_questions(elo_range: Curriculum.grade("3-klas").range, grade: Curriculum.grade("3-klas"))

    expect(test_questions.size).to eq(Curriculum::TEST_LENGTH)
    expect(test_questions.map(&:id) & samples.map(&:id)).to be_empty
  end

  it "shows the paper without the answers" do
    get "/matematika/3-klas/test"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<h1 class=\"landing-h1 mb-4\">#{I18n.t("curriculum.test.title", grade: 3)}</h1>")
    expect(response.body).to include(I18n.t("curriculum.test.hand_in"))
    expect(response.body).not_to include("6 · 4 = 24", "56 : 8 = 7")
    expect(response.body).not_to include("noindex")
  end

  it "marks what is handed in and shows the solution under each problem" do
    answers = test_questions.to_h do |question|
      value = if question.multiple_choice?
        { selected_ids: [ question.correct_possible_answers.first.id ] }
      else
        { value: "24" }
      end
      [ question.id.to_s, value ]
    end

    post "/matematika/3-klas/test", params: { answers: answers }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("curriculum.test.score", score: 10, count: 10))
    expect(response.body).to include("6 · 4 = 24")
  end

  it "counts a wrong and a blank answer as wrong, and says which is which" do
    first, second, = test_questions
    wrong = first.multiple_choice? ? { selected_ids: [ first.possible_answers.reject(&:correct?).first.id ] } : { value: "25" }

    post "/matematika/3-klas/test", params: { answers: { first.id.to_s => wrong } }

    expect(response.body).to include(I18n.t("curriculum.test.score", score: 0, count: 10))
    expect(response.body).to include(I18n.t("curriculum.test.wrong"), I18n.t("curriculum.test.blank"))
    expect(second).to be_present
  end

  it "accepts an answer the way the app does: 24,0 is 24" do
    exact = test_questions.reject(&:multiple_choice?).first

    post "/matematika/3-klas/test", params: { answers: { exact.id.to_s => { value: "24,0" } } }

    expect(response.body).to include(I18n.t("curriculum.test.score", score: 1, count: 10))
  end

  it "stores nothing and moves no rating" do
    question = test_questions.first

    expect {
      post "/matematika/3-klas/test", params: { answers: { question.id.to_s => { value: "24" } } }
    }.not_to change { [ UserAnswer.count, question.reload.elo ] }
  end

  it "ignores answers to problems that are not on the paper" do
    other = create(:question, status: :published, elo: 2500, answer: "1")

    post "/matematika/3-klas/test", params: { answers: { other.id.to_s => { value: "1" } } }

    expect(response.body).to include(I18n.t("curriculum.test.score", score: 0, count: 10))
  end

  it "is in the sitemap, and a grade with nothing to set is not" do
    get "/sitemap.xml"

    expect(response.body).to include("/matematika/3-klas/test</loc>")
    expect(response.body).not_to include("/matematika/12-klas/test</loc>")
  end

  it "is linked from its grade's strip only where there is a test" do
    get "/matematika/3-klas"
    expect(response.body).to include('href="/matematika/3-klas/test"')

    get "/matematika/formuli/12-klas"
    get "/matematika"
    expect(response.body).to include('href="/matematika/3-klas/test"')
    expect(response.body).not_to include('href="/matematika/12-klas/test"')
  end

  # The page is public, so its address and its form are both inputs: none of
  # these may be more than a paper with no answers on it.
  describe "answers that are not answers" do
    let(:choice) { test_questions.find(&:multiple_choice?) }
    let(:exact) { test_questions.reject(&:multiple_choice?).first }

    it "shows the paper for a GET that carries them" do
      get "/matematika/3-klas/test", params: { answers: "x" }
      expect(response).to have_http_status(:ok)

      get "/matematika/3-klas/test?answers[]=x"
      expect(response).to have_http_status(:ok)
    end

    it "marks every shape of nonsense as no answer" do
      [
        { answers: "x" },
        { answers: [ "x" ] },
        { answers: { exact.id.to_s => "x" } },
        { answers: { exact.id.to_s => { value: { a: 1 } } } },
        { answers: { exact.id.to_s => { value: [ "24" ] } } },
        { answers: { choice.id.to_s => { selected_ids: { x: 1 } } } },
        { answers: { choice.id.to_s => { selected_ids: [ { x: 1 } ] } } },
        { answers: { choice.id.to_s => { selected_ids: "7" } } }
      ].each do |params|
        post "/matematika/3-klas/test", params: params

        expect(response).to have_http_status(:ok), params.inspect
        expect(response.body).to include(I18n.t("curriculum.test.score", score: 0, count: 10)), params.inspect
      end
    end
  end

  it "answers a format it has no page for with 406, not an error" do
    get "/matematika/3-klas/test.json"
    expect(response).to have_http_status(:not_acceptable)

    post "/matematika/3-klas/test.json", params: { answers: {} }
    expect(response).to have_http_status(:not_acceptable)
  end

  it "has no page for a grade with nothing to set" do
    get "/matematika/12-klas/test"

    expect(response).to have_http_status(:not_found)
  end
end
