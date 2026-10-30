require "rails_helper"

# What the question screen hands a child to answer with. A numeric question
# gets the number pad (answers/_number_pad) and no MathLive; „Чернова" has a
# door under the answer controls and is marked to open by itself beside a
# problem worth working out (see ApplicationHelper#scratchpad_suggested?).
describe "Answer inputs", type: :request do
  let(:student) { create(:user, elo: 1200) }

  def question_screen_for(question)
    assignment = Assignment.create!(user: student)
    assignment_question = assignment.assignment_questions.create!(question: question, position: 1)
    sign_in student
    get question_path(assignment_question)
    Nokogiri::HTML(response.body)
  end

  it "gives a numeric question the number pad" do
    page = question_screen_for(create(:question, answer: "3/4"))

    page.at_css('[data-controller="number-pad"]').should be_present
    page.at_css('input[type="hidden"][name="value"][data-number-pad-target="hidden"]').should be_present
    page.css(".number-pad-key").map { |key| key.text.strip }.should include("0", "7", ",")
    page.at_css('[data-controller~="math-input"], math-field').should be_nil
  end

  it "keeps a plain text field for an answer that is not a number" do
    page = question_screen_for(create(:question, answer: "триъгълник"))

    page.at_css('[data-controller="number-pad"]').should be_nil
    page.at_css('input[type="text"][name="value"]').should be_present
  end

  it "offers the scratch paper under the answer, and opens it by itself only for a long problem" do
    short = question_screen_for(create(:question, text: "Колко е 6 · 7?"))
    short.at_css(".scratchpad-open-button").should be_present
    short.at_css(".practice-shell")["data-scratchpad-suggested-value"].should eq("false")

    long_text = "Мама купила 3 кг ябълки по 2,40 евро и 2 кг круши по 3,10 евро. Колко евро ресто е получила от 20 евро?"
    long = question_screen_for(create(:question, text: long_text, answer: "6,6"))
    long.at_css(".practice-shell")["data-scratchpad-suggested-value"].should eq("true")
  end
end
