require "rails_helper"

describe "Challenges", type: :request do
  let!(:questions) { create_list(:question, Challenge::QUESTION_COUNT, elo: 1050) }
  let(:alice) { create(:user, nickname: "alice") }
  let(:bob) { create(:user, nickname: "bob") }

  def answer_everything(challenge, value:)
    challenge.challenge_questions.each do |challenge_question|
      get "/challenges/#{challenge.id}"
      post "/challenges/#{challenge.id}/answers",
           params: { challenge_question_id: challenge_question.id, value: value }
    end
  end

  it "runs a duel from lobby to result" do
    sign_in alice
    post "/challenges"
    challenge = Challenge.last
    challenge.should be_waiting

    get "/challenges/#{challenge.id}"
    response.body.should include(I18n.t("challenges.searching"))

    sign_in bob
    post "/challenges"
    challenge.reload.should be_active
    challenge.users.should match_array([ alice, bob ])

    # Bob clears the lot; the match stays live until Alice is done too.
    answer_everything(challenge, value: "42")
    challenge.reload.should be_active
    get "/challenges/#{challenge.id}"
    response.body.should include(I18n.t("challenges.done_waiting"))

    sign_in alice
    answer_everything(challenge, value: "41")

    challenge.reload.should be_finished
    challenge.winner_id.should eq(bob.id)

    get "/challenges/#{challenge.id}"
    response.body.should include(I18n.t("challenges.you_lost"))
    response.body.should include("bob")
  end

  it "serves the problem before it will take an answer for it" do
    sign_in alice
    post "/challenges"
    sign_in bob
    post "/challenges"
    challenge = Challenge.last

    get "/challenges/#{challenge.id}"
    challenge.participant_for(bob).reload.question_started_at.should be_present
  end

  it "reports the live state as JSON" do
    sign_in alice
    post "/challenges"
    sign_in bob
    post "/challenges"
    challenge = Challenge.last

    get "/challenges/#{challenge.id}/state"

    state = JSON.parse(response.body)
    state["status"].should eq("active")
    state["seconds_left"].should be <= challenge.time_limit_seconds
    state["opponent"]["name"].should eq("alice")
    state["you"]["answered"].should eq(0)
  end

  it "shows an opponent without a nickname anonymously" do
    nameless = create(:user, name: "Иван Иванов", nickname: nil)

    sign_in nameless
    post "/challenges"
    sign_in alice
    post "/challenges"
    challenge = Challenge.last

    get "/challenges/#{challenge.id}"
    response.body.should_not include("Иван Иванов")
    response.body.should include(I18n.t("challenges.anonymous_opponent"))
  end

  it "lets a player abandon a lobby but not a live match" do
    sign_in alice
    post "/challenges"
    challenge = Challenge.last

    delete "/challenges/#{challenge.id}"
    challenge.reload.should be_abandoned

    post "/challenges"
    started = Challenge.last
    sign_in bob
    post "/challenges"
    started.reload.should be_active

    sign_in alice
    delete "/challenges/#{started.id}"
    started.reload.should be_active
  end

  it "closes a lobby nobody joined, for the player waiting in it" do
    sign_in alice
    post "/challenges"
    challenge = Challenge.last
    challenge.update!(created_at: (Challenge::LOBBY_TTL + 1.minute).ago)

    get "/challenges/#{challenge.id}/state"
    JSON.parse(response.body)["status"].should eq("abandoned")

    get "/challenges/#{challenge.id}"
    response.body.should include(I18n.t("challenges.abandoned"))
  end

  it "keeps other people out of a match they are not in" do
    sign_in alice
    post "/challenges"
    sign_in bob
    post "/challenges"
    challenge = Challenge.last

    sign_in create(:user)
    get "/challenges/#{challenge.id}"
    response.should have_http_status(:not_found)

    post "/challenges/#{challenge.id}/answers",
         params: { challenge_question_id: challenge.challenge_questions.first.id, value: "42" }
    response.should have_http_status(:not_found)
  end

  it "keeps parents out of the duel screens" do
    sign_in create(:user, role: :parent, verified_at: Time.current)

    get "/challenges"
    response.should redirect_to("/parents/children")

    post "/challenges"
    response.should redirect_to("/parents/children")
    Challenge.count.should eq(0)
  end

  it "says so when the bank cannot fill a duel" do
    Question.update_all(status: Question.statuses[:draft])

    sign_in alice
    post "/challenges"

    response.should redirect_to("/challenges")
    flash[:alert].should eq(I18n.t("challenges.not_enough_questions"))
  end

  it "does not grade a blank submission" do
    sign_in alice
    post "/challenges"
    sign_in bob
    post "/challenges"
    challenge = Challenge.last

    get "/challenges/#{challenge.id}"
    post "/challenges/#{challenge.id}/answers",
         params: { challenge_question_id: challenge.challenge_questions.first.id, value: "" }

    flash[:alert].should eq(I18n.t("answers.blank"))
    challenge.participant_for(bob).challenge_answers.should be_empty
  end

  it "shows the duel record and history on the index" do
    sign_in alice
    post "/challenges"
    sign_in bob
    post "/challenges"
    challenge = Challenge.last
    answer_everything(challenge, value: "42")
    challenge.update!(started_at: (challenge.time_limit_seconds + 1).seconds.ago)
    get "/challenges/#{challenge.id}"

    get "/challenges"
    response.body.should include(I18n.t("duel.recent"))
    response.body.should include("alice")
    ChallengeRecord.for(bob).won.should eq(1)
  end
end
