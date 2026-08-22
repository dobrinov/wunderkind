require "rails_helper"

# Anyone signed in — student or parent — can suggest a problem. It
# enters the admin review queue as an ordinary in_review question, and once
# published it credits the suggester wherever it is asked.
describe "Problem suggestions", type: :request do
  let(:student) { create(:user, role: :student, elo: 900, nickname: "eli_star") }
  let(:topic) { Topic.create!(name: "Дроби", parent: Topic.create!(name: "Аритметика")) }

  # What the editor submits: the typed text as a plain document, fractions
  # not yet promoted — that is the server's job.
  def doc(text)
    { type: "doc", content: [ { type: "paragraph", content: [ { type: "text", text: text } ] } ] }.to_json
  end

  def suggest(overrides = {})
    post "/suggestions", params: { suggestion: {
      body_json: doc("Колко е 1/2 + 1/4?"), answer: "3/4", topic_id: topic.id
    }.merge(overrides) }
  end

  it "requires sign-in" do
    get "/suggestions"
    response.should redirect_to("/sign-in")
  end

  it "files a suggestion into the review queue, credited and at the suggester's rating" do
    sign_in student
    suggest(explanation: "Привеждаме към общ знаменател.")

    response.should redirect_to("/suggestions")

    question = Question.last
    question.status.should eq("in_review")
    question.suggested_by.should eq(student)
    question.author.should eq(student)
    question.elo.should eq(900)
    question.answer_type.should eq("exact_value")
    question.grading["expected"].should eq("3/4")
    question.explanation.should eq("Привеждаме към общ знаменател.")
    question.topics.should eq([ topic ])
  end

  it "promotes bare fractions typed in the editor to math nodes, like a problem file" do
    sign_in student
    suggest

    nodes = Question.last.body["content"].first["content"]
    nodes.any? { |node| node["type"] == "math" && node.dig("attrs", "latex") == "\\frac{1}{2}" }.should be(true)
    Question.last.body_text.should eq("Колко е 1/2 + 1/4?")
  end

  it "builds a multiple-choice question from options with the right ones marked" do
    sign_in student
    suggest(answer_type: "multiple_choice", answer: "",
            body_json: doc("Кое е най-голямото едноцифрено число?"),
            options: { "0" => { value: "9", correct: "1" }, "1" => { value: "8" }, "2" => { value: "" } })

    question = Question.last
    question.answer_type.should eq("multiple_choice")
    question.possible_answers.map(&:value).should eq([ "9", "8" ])
    question.possible_answers.map(&:correct).should eq([ true, false ])
    question.grading.should eq({})
  end

  it "rejects a multiple choice with no correct option marked" do
    sign_in student
    suggest(answer_type: "multiple_choice", answer: "",
            options: { "0" => { value: "9" }, "1" => { value: "8" } })

    response.should have_http_status(:unprocessable_entity)
    Question.count.should eq(0)
  end

  it "rejects a multiple choice with fewer than two options" do
    sign_in student
    suggest(answer_type: "multiple_choice", answer: "",
            options: { "0" => { value: "9", correct: "1" } })

    response.should have_http_status(:unprocessable_entity)
    Question.count.should eq(0)
  end

  it "attaches an uploaded picture to the question" do
    sign_in student
    suggest(image: fixture_file_upload("figure.png", "image/png"))

    Question.last.image.file.should be_attached
  end

  it "rejects a file that is not a picture" do
    sign_in student
    suggest(image: fixture_file_upload("figure.png", "application/pdf"))

    response.should have_http_status(:unprocessable_entity)
    Question.count.should eq(0)
  end

  it "rejects an empty editor document" do
    sign_in student
    suggest(body_json: { type: "doc", content: [ { type: "paragraph" } ] }.to_json)

    response.should have_http_status(:unprocessable_entity)
    Question.count.should eq(0)
  end

  it "rejects an answer that is not a value" do
    sign_in student
    suggest(answer: "може би пет")

    response.should have_http_status(:unprocessable_entity)
    Question.count.should eq(0)
  end

  it "rejects a problem the bank already knows" do
    create(:question, text: "Колко е 1/2 + 1/4?")
    sign_in student
    suggest

    response.should have_http_status(:unprocessable_entity)
    Question.where(suggested_by: student).count.should eq(0)
  end

  it "is open to parents too" do
    sign_in create(:user, role: :parent, verified_at: Time.current)
    suggest(text: "Колко е 9 · 9?", answer: "81")
    Question.last.suggested_by.role.should eq("parent")
  end

  it "lists only the suggester's own suggestions" do
    other = create(:user)
    create(:question, text: "Чужда задача 3 + 4", suggested_by: other, status: :in_review)
    mine = create(:question, text: "Моя задача 2 + 2", suggested_by: student, status: :in_review)

    sign_in student
    get "/suggestions"

    response.body.should include(mine.body_text)
    response.body.should_not include("Чужда задача")
  end

  it "credits the suggester on the practice screen, nickname first" do
    question = create(:question, text: "Колко е 15 - 6?", answer: "9", suggested_by: student)
    solver = create(:user)
    assignment = Assignment.create!(user: solver, kind: :practice)
    assignment_question = assignment.assignment_questions.create!(question: question, position: 1)

    sign_in solver
    get "/questions/#{assignment_question.id}"

    response.body.should include("eli_star")
    response.body.should_not include(student.name)
  end

  it "shows no credit on a question nobody suggested" do
    question = create(:question, text: "Колко е 2 + 2?")
    assignment = Assignment.create!(user: student, kind: :practice)
    assignment_question = assignment.assignment_questions.create!(question: question, position: 1)

    sign_in student
    get "/questions/#{assignment_question.id}"

    response.body.should_not include("suggested-pill")
  end

  it "keeps the credit through admin review" do
    admin = create(:user, role: :admin)
    sign_in student
    suggest

    question = Question.last
    sign_in admin
    post "/overseer/reviews/#{question.id}/approve"

    question.reload.status.should eq("published")
    question.suggested_by.should eq(student)
  end
end
