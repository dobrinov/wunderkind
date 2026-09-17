require "rails_helper"

# Instrumentation is the one kind of code that fails silently by design: a goal
# that never fires looks exactly like a goal nobody reached, and the difference
# only turns up a month later when somebody asks why the number is zero. So the
# events are tested where they are decided — in the controller, as the meta tag
# the next page carries (see shared/_analytics and lib/analytics.js).
describe "Analytics events", type: :request do
  # The meta tag is a JSON blob, HTML-escaped into the attribute. Read it back
  # rather than matching on a string, so a spec cannot pass on a half-written tag.
  def tracked_event
    content = response.body[/<meta name="analytics-event" content="([^"]*)">/, 1]
    return nil if content.nil?

    JSON.parse(CGI.unescapeHTML(content))
  end

  # Every event rides one redirect, which is the whole reason it is a flash.
  def follow_and_read_event
    follow_redirect!
    tracked_event
  end

  describe "signing up" do
    it "counts the new account with the role it chose" do
      post "/sign-up", params: { name: "Нов Ученик", email: "new@example.com", password: "password", role: "parent" }

      follow_and_read_event.should eq("name" => "Signup", "props" => { "role" => "parent" })
    end

    it "survives the reset_session that signing up does on the way past" do
      post "/sign-up", params: { name: "Нов Ученик", email: "kid@example.com", password: "password" }

      follow_and_read_event["props"].should eq("role" => "student")
    end

    it "counts nothing when the account was not created" do
      post "/sign-up", params: { name: "", email: "", password: "" }

      tracked_event.should be_nil
    end
  end

  describe "a practice session" do
    let(:student) { create(:user, elo: 1200) }

    before { create_list(:question, 15, :published, elo: 1200) }

    it "counts the session when it is started" do
      sign_in student

      post "/assignments"

      follow_and_read_event.should eq("name" => "Session Started", "props" => { "kind" => "practice" })
    end

    it "counts the session again when the last answer lands, and not before" do
      assignment = Assignment.create!(user: student)
      2.times do |index|
        assignment.assignment_questions.create!(question: create(:question, :published, answer: "42"), position: index + 1)
      end
      sign_in student

      post "/questions/#{assignment.assignment_questions.first.id}/answer", params: { value: "42" }
      follow_and_read_event.should be_nil

      post "/questions/#{assignment.assignment_questions.second.id}/answer", params: { value: "42" }
      follow_and_read_event.should eq("name" => "Session Completed", "props" => { "kind" => "practice" })
    end

    it "counts a session the student finished by skipping the last question" do
      assignment = Assignment.create!(user: student)
      assignment.assignment_questions.create!(question: create(:question, :published), position: 1)
      sign_in student

      post "/questions/#{assignment.assignment_questions.first.id}/skip"

      follow_and_read_event["name"].should eq("Session Completed")
    end
  end

  describe "reporting a broken problem" do
    let(:student) { create(:user) }

    it "counts the report with the reason, and where it was filed from" do
      assignment = Assignment.create!(user: student)
      assignment_question = assignment.assignment_questions.create!(question: create(:question, :published), position: 1)
      sign_in student

      post "/questions/#{assignment_question.id}/report", params: { reason: "wrong_answer" }

      follow_and_read_event.should eq(
        "name" => "Problem Reported",
        "props" => { "reason" => "wrong_answer", "from" => "practice" }
      )
    end

    it "counts nothing when no reason was given" do
      assignment = Assignment.create!(user: student)
      assignment_question = assignment.assignment_questions.create!(question: create(:question, :published), position: 1)
      sign_in student

      post "/questions/#{assignment_question.id}/report", params: { reason: "" }

      follow_and_read_event.should be_nil
    end
  end

  describe "suggesting a problem" do
    it "counts the suggestion with the kind of answer it carries" do
      student = create(:user)
      topic = Topic.create!(name: "Дроби")
      body = { type: "doc", content: [ { type: "paragraph", content: [ { type: "text", text: "Колко е 2 + 2?" } ] } ] }
      sign_in student

      post "/suggestions", params: {
        suggestion: { body_json: body.to_json, answer: "4", topic_id: topic.id }
      }

      follow_and_read_event.should eq(
        "name" => "Problem Suggested",
        "props" => { "answer_type" => "exact_value" }
      )
    end
  end

  # The script itself is the one part nothing else would catch: a wrong URL or a
  # broken init() fails by collecting nothing at all, quietly, in production only.
  describe "the script" do
    it "is absent outside production, and absent for an admin in it" do
      get root_path
      response.body.should_not include("plausible.init")

      Rails.env.stub(:production?).and_return(true)
      sign_in create(:user, role: :admin)
      get "/overseer"
      response.body.should_not include("plausible.init")
    end

    it "loads on the public page in production, with ids folded out of the path" do
      Rails.env.stub(:production?).and_return(true)

      get root_path

      response.body.should include(%(src="#{Analytics.script_url}"))
      response.body.should include("plausible.init({ transformRequest:")
      # The one line that keeps thirty thousand question pages from becoming
      # thirty thousand rows in Top Pages.
      response.body.should include('replace(/\/\d+(?=\/|$)/g, "/:id")')
    end
  end

  describe "the queue itself" do
    it "holds one event for exactly one page" do
      sign_in create(:user)
      create_list(:question, 15, :published, elo: 1200)

      post "/assignments"
      follow_redirect!
      tracked_event.should be_present

      get "/calendar"
      tracked_event.should be_nil
    end
  end
end
