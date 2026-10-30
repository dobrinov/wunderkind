require "rails_helper"

# The admin authoring form writes a problem as plain text — the same language
# as a problem file and /suggestions, plus `$…$` for LaTeX — and reopens a
# stored one as that text.
describe "Authoring questions", type: :request do
  let(:admin) { create(:user, role: :admin, verified_at: Time.current) }
  let(:topic) { Topic.create!(name: "Дроби") }

  def question_params(overrides = {})
    { question: { body_source: "Колко е 3/4 от $\\sqrt{16}$?", answer_type: "exact_value", expected: "3",
                  status: "published", elo: 900, topic_ids: [ topic.id ] }.merge(overrides) }
  end

  before { sign_in admin }

  it "promotes a typed fraction and reads $…$ as LaTeX" do
    post "/overseer/questions", params: question_params

    response.should redirect_to("/overseer/questions")
    Question.last.body.dig("content", 0, "content").should eq([
      { "type" => "text", "text" => "Колко е " },
      { "type" => "math", "attrs" => { "latex" => "\\frac{3}{4}" } },
      { "type" => "text", "text" => " от " },
      { "type" => "math", "attrs" => { "latex" => "\\sqrt{16}" } },
      { "type" => "text", "text" => "?" }
    ])
  end

  # The form always carries one empty option row, whose "correct" checkbox
  # sends a hidden "0". That used to fail every save of a question that is not
  # multiple choice — 96% of the bank — with „Possible answers value не може да
  # е празно".
  it "saves an exact-value question with the form's empty option row" do
    question = create(:question, answer: "3", topics: [ topic ])
    empty_row = { "0" => { value: "", correct: "0" } }

    patch "/overseer/questions/#{question.id}",
          params: question_params(expected: "4", tolerance: "0,5", possible_answers_attributes: empty_row)

    response.should be_redirect
    question.reload.grading.should eq("expected" => "4", "tolerance" => 0.5)
    question.possible_answers.should be_empty
  end

  it "still adds a typed option and drops the empty one on a multiple-choice question" do
    post "/overseer/questions", params: question_params(
      answer_type: "multiple_choice",
      possible_answers_attributes: { "0" => { value: "3", correct: "1" }, "1" => { value: "4", correct: "0" }, "2" => { value: "", correct: "0" } }
    )

    Question.last.possible_answers.map(&:value).should eq(%w[3 4])
  end

  it "reopens a stored question as the text it was written in" do
    question = create(:question, text: "Ани изяде 1/2 от пицата.\nКолко остана?")

    get "/overseer/questions/#{question.id}/edit"

    response.body.should include("Ани изяде 1/2 от пицата.\nКолко остана?</textarea>")
    response.body.should include('<span class="frac" role="math" aria-label="1/2"><span aria-hidden="true">1</span><span aria-hidden="true">2</span></span>')
  end

  # Opening a question and saving it untouched is the commonest edit there is
  # (a status, an Elo), and it must not move body_text, which the importer
  # dedupes on.
  it "saves an untouched body back exactly as it was" do
    question = create(:question, text: "Сравни 1/2 и 3/4, а после 0,5/2.")
    body = question.body

    get "/overseer/questions/#{question.id}/edit"
    source = CGI.unescapeHTML(response.body[%r{<textarea[^>]*name="question\[body_source\]"[^>]*>\n?(.*?)</textarea>}m, 1])
    patch "/overseer/questions/#{question.id}", params: question_params(body_source: source, expected: "42")

    question.reload.body.should eq(body)
    question.body_text.should eq("Сравни 1/2 и 3/4, а после 0,5/2.")
  end

  # No form sends a document any more, but anything that assigns one (a
  # console, a script, a future importer) is held to the same schema.
  it "refuses to store a body that is not a document of the restricted kind" do
    question = build(:question, body: { "type" => "doc", "content" => [ { "type" => "heading", "content" => [] } ] })

    question.should_not be_valid
    question.errors.should include(:body)
  end

  it "still saves a stored row whose body it did not touch" do
    question = create(:question)
    question.update_column(:body, { "type" => "doc", "content" => [ { "type" => "blockquote", "content" => [ { "type" => "text", "text" => "Стар ред" } ] } ] })

    question.reload.update(status: :retired).should be(true)
  end

  it "refuses an empty body" do
    post "/overseer/questions", params: question_params(body_source: "\n")

    response.should have_http_status(:unprocessable_entity)
    Question.count.should eq(0)
  end
end
