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
      # A student lands on the placement welcome; the event has to ride the
      # flash all the way there, through the session reset on the way.
      post "/sign-up", params: { name: "Нов Ученик", email: "kid@example.com", password: "password" }

      follow_and_read_event["props"].should eq("role" => "student")
    end

    it "counts nothing when the account was not created" do
      post "/sign-up", params: { name: "", email: "", password: "" }

      tracked_event.should be_nil
    end
  end

  # Coming back and doing something: the engagement half of trace.json's KPIs.
  describe "using the app once signed up" do
    it "counts a sign-in, with who signed in" do
      student = create(:user, role: :student)
      sign_in student

      follow_and_read_event.should eq("name" => "Login", "props" => { "role" => "student", "via" => "password" })
    end

    it "counts nothing for a wrong password" do
      post "/sign-in", params: { email: create(:user).email, password: "wrong" }

      tracked_event.should be_nil
    end

    it "counts a parent handing the device to a managed child as that child's sign-in" do
      parent = create(:user, role: :parent, verified_at: Time.current)
      child = User.create_managed_child!(parent: parent, name: "Мими")
      sign_in parent

      post "/switch-child/#{child.id}"

      follow_and_read_event.should eq("name" => "Login", "props" => { "role" => "student", "via" => "switch" })
    end

    it "counts a goal a parent sets" do
      parent = create(:user, role: :parent, verified_at: Time.current)
      child = create(:user, name: "Мими")
      parent.parent_links.create!(child: child)
      sign_in parent

      post "/parents/children/#{child.id}/goals", params: {
        goal: { metric: "problems", mode: "total", period: "week", threshold: "15", target: "5", total_target: "100", reward: "Кино" }
      }

      follow_and_read_event.should eq("name" => "Goal Created", "props" => { "metric" => "problems", "mode" => "total" })
    end

    it "counts joining a league, by creating one or by its code" do
      owner = create(:user, role: :student)
      sign_in owner
      post "/leagues", params: { league: { name: "3 „Б“", friend_ids: [] } }
      follow_and_read_event.should eq("name" => "League Joined", "props" => { "how" => "created" })

      sign_in create(:user, role: :student)
      post "/leagues/join", params: { code: League.sole.code }
      follow_and_read_event.should eq("name" => "League Joined", "props" => { "how" => "code" })
    end

    # Trace counts these from the form's submit; nothing rides the flash.
    it "marks the answer form and the skip button for Trace" do
      sign_in create(:user)
      create_list(:question, 15, :published, elo: 1200)
      post "/assignments"
      follow_redirect!

      response.body.should include('data-trace-event="problem_answered"')
      response.body.should include('data-trace-event="problem_skipped"')
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
      sign_in student

      post "/suggestions", params: {
        suggestion: { text: "Колко е 2 + 2?", answer: "4", topic_id: topic.id }
      }

      follow_and_read_event.should eq(
        "name" => "Problem Suggested",
        "props" => { "answer_type" => "exact_value" }
      )
    end
  end

  # Trace is sent each event under its key, which lib/analytics.js derives from
  # the Plausible name. A name that does not fold back to its key is an event
  # trace.json never sees.
  it "names every event the same way for both dashboards" do
    Analytics::EVENTS.each do |key, name|
      name.downcase.tr(" ", "_").should eq(key.to_s)
    end
  end

  # The script itself is the one part nothing else would catch: a wrong URL or a
  # broken init() fails by collecting nothing at all, quietly, in production only.
  describe "the script" do
    it "is absent outside production, and absent for an admin in it" do
      get root_path
      response.body.should_not include("plausible.init")
      response.body.should_not include("/d.js?k=")

      Rails.env.stub(:production?).and_return(true)
      sign_in create(:user, role: :admin)
      get "/overseer"
      response.body.should_not include("plausible.init")
      response.body.should_not include("/d.js?k=")
    end

    it "loads on the public page in production, with ids folded out of the path" do
      Rails.env.stub(:production?).and_return(true)

      get root_path

      response.body.should include(%(src="#{Analytics.script_url}"))
      response.body.should include("plausible.init({ transformRequest:")
      # Trace beside it, cookieless: nothing on the device, so no consent bar.
      response.body.should include(%(src="#{Analytics.trace_script_url}"))
      response.body.should_not include("data-consent")
      # The one line that keeps thirty thousand question pages from becoming
      # thirty thousand rows in Top Pages.
      response.body.should include('replace(/\/\d+(?=\/|$)/g, "/:id")')
    end
  end

  # DAU, MAU and retention need Trace to know a returning person, and nothing
  # else: a keyed hash on pages for someone signed in, nothing for a visitor.
  describe "who is signed in" do
    it "is a keyed hash for a signed-in student, and absent for a visitor" do
      Rails.env.stub(:production?).and_return(true)
      get root_path
      response.body.should_not include("trace-identity")

      student = create(:user)
      sign_in student
      get "/home"
      response.body.should include(%(<meta name="trace-identity" content="#{Analytics.trace_identity(student)}">))
      response.body.should_not include(%(content="#{student.id}"))
    end

    it "is never written for an admin" do
      Rails.env.stub(:production?).and_return(true)
      sign_in create(:user, role: :admin)
      get "/overseer"
      response.body.should_not include("trace-identity")
    end

    # Signing in turns a stranger's page, scripts already running, into the
    # admin's: Turbo keeps the scripts, so the page has to tell them to stop.
    it "tells the scripts to stop once an admin is signed in" do
      sign_in create(:user, role: :admin)
      get "/overseer"
      response.body.should include('<meta name="analytics-off" content="admin">')

      sign_in create(:user)
      get "/home"
      response.body.should_not include("analytics-off")
    end
  end

  describe "the queue itself" do
    it "holds one event for exactly one page" do
      sign_in create(:user)
      create_list(:question, 15, :published, elo: 1200)

      post "/assignments"
      follow_redirect!
      tracked_event.should be_present

      get "/home"
      tracked_event.should be_nil
    end
  end
end
