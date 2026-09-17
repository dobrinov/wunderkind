require "rails_helper"

# The cue itself is browser-side, but the whole feature hangs on the server
# answering the same POST two ways: a redirect for a plain form, and the verdict
# plus that redirect for the answer form's fetch. It has to be the fetch,
# because only the page the student is still looking at is allowed to start
# audio in Safari and Firefox — see app/javascript/lib/sounds.js.
describe "Answer sounds", type: :request do
  let(:student) { create(:user, elo: 1200) }

  def assignment_with(count, *traits, **question_attributes)
    assignment = Assignment.create!(user: student)
    count.times do |index|
      assignment.assignment_questions.create!(question: create(:question, *traits, **question_attributes), position: index + 1)
    end
    assignment
  end

  def answer(assignment_question, value:)
    post "/questions/#{assignment_question.id}/answer",
         params: { value: value },
         headers: { "Accept" => "application/json" }
  end

  describe "the practice flow" do
    it "names the verdict and where to go next for a correct answer" do
      assignment = assignment_with(2, answer: "42")
      assignment_question = assignment.assignment_questions.first

      sign_in student
      answer(assignment_question, value: "42")

      response.should have_http_status(:ok)
      body = response.parsed_body
      body["verdict"].should eq("correct")
      body["redirect"].should eq(question_path(assignment.assignment_questions.second))
    end

    it "names a wrong answer wrong" do
      assignment_question = assignment_with(2, answer: "42").assignment_questions.first

      sign_in student
      answer(assignment_question, value: "41")

      response.parsed_body["verdict"].should eq("wrong")
    end

    it "sends the student to the feedback card when feedback is on" do
      student.update!(feedback_after_answer: true)
      assignment_question = assignment_with(2, answer: "42").assignment_questions.first

      sign_in student
      answer(assignment_question, value: "42")

      response.parsed_body["redirect"].should eq(question_path(assignment_question))
    end

    it "keeps the plain form post on its redirect" do
      assignment = assignment_with(2, answer: "42")
      assignment_question = assignment.assignment_questions.first

      sign_in student
      post "/questions/#{assignment_question.id}/answer", params: { value: "42" }

      response.should redirect_to(question_path(assignment.assignment_questions.second))
    end

    # Nothing was graded, so there is nothing to sound — but the client still
    # needs somewhere to go, or it would be left on a dimmed form.
    it "has no verdict for an answer that never arrived" do
      assignment_question = assignment_with(2, answer: "42").assignment_questions.first

      sign_in student
      answer(assignment_question, value: "")

      response.parsed_body["verdict"].should be_nil
      response.parsed_body["redirect"].should eq(question_path(assignment_question))
      assignment_question.reload.user_answer.should be_nil
    end

    # A skip is neither right nor wrong, and it is posted by its own button
    # rather than by the answer form.
    it "leaves a skip silent and redirecting" do
      assignment = assignment_with(2, answer: "42")
      assignment_question = assignment.assignment_questions.first

      sign_in student
      post "/questions/#{assignment_question.id}/skip", headers: { "Accept" => "application/json" }

      response.should redirect_to(question_path(assignment.assignment_questions.second))
    end

    it "says nothing for a free-text answer, which is not graded yet" do
      assignment_question = assignment_with(2, :free_text).assignment_questions.first

      sign_in student
      answer(assignment_question, value: "защото 13 - 8 = 5")

      response.parsed_body["verdict"].should be_nil
      assignment_question.reload.user_answer.should be_pending_review
    end
  end

  describe "duels" do
    let!(:questions) { create_list(:question, Challenge::QUESTION_COUNT, elo: 1050, answer: "42") }
    let(:opponent) { create(:user, nickname: "bob") }

    it "sounds a duel answer the same way" do
      sign_in student
      post "/challenges"
      sign_in opponent
      post "/challenges"

      challenge = Challenge.last
      challenge_question = challenge.challenge_questions.first
      path = challenge_path(challenge, close_path: challenges_path)

      get "/challenges/#{challenge.id}"
      post "/challenges/#{challenge.id}/answers",
           params: { challenge_question_id: challenge_question.id, value: "42" },
           headers: { "Accept" => "application/json" }

      response.parsed_body["verdict"].should eq("correct")
      response.parsed_body["redirect"].should eq(path)
    end
  end

  describe "the switch" do
    it "starts on for a new student" do
      create(:user).sound_effects.should be(true)
    end

    it "tells the page which way it is set" do
      student.update!(sound_effects: false)
      assignment_question = assignment_with(1, answer: "42").assignment_questions.first

      sign_in student
      get "/questions/#{assignment_question.id}"

      response.body.should include('<meta name="sound-effects" content="false">')
      response.body.should include(I18n.t("sound.disabled"))
    end

    it "offers the speaker button on the practice screen" do
      assignment_question = assignment_with(1, answer: "42").assignment_questions.first

      sign_in student
      get "/questions/#{assignment_question.id}"

      response.body.should include('<meta name="sound-effects" content="true">')
      response.body.should include(sound_profile_path)
      response.body.should include(I18n.t("sound.label"))
    end

    it "is flipped by the speaker button without a redirect to sit through" do
      sign_in student

      patch sound_profile_path, params: { enabled: false }, as: :json

      response.should have_http_status(:no_content)
      student.reload.sound_effects.should be(false)

      patch sound_profile_path, params: { enabled: true }, as: :json
      student.reload.sound_effects.should be(true)
    end

    it "is the same switch as the one in the settings form" do
      sign_in student

      put "/profile", params: { user: { sound_effects: "0" } }

      student.reload.sound_effects.should be(false)
      get "/profile"
      response.body.should include(I18n.t("profile.sound_effects"))
    end

    it "is nobody's business when signed out" do
      get "/sign-in"

      response.body.should include('<meta name="sound-effects" content="false">')
    end

    # The speaker button is a specimen there rather than anybody's setting, and
    # in development that page has no one signed in to have a preference.
    it "renders on the design system with nobody signed in" do
      allow(Rails.env).to receive(:development?).and_return(true)

      get "/design-system"

      response.should have_http_status(:ok)
      response.body.should include("sound-demo")
      response.body.should include(I18n.t("sound.label"))
    end
  end
end
