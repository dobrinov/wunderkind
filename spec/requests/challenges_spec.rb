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

  it "runs a duel from lobby to ready room to result" do
    sign_in alice
    post "/challenges"
    challenge = Challenge.last
    challenge.should be_waiting

    get "/challenges/#{challenge.id}"
    response.body.should include(I18n.t("challenges.searching"))

    # The second player fills the lobby — and starts nothing. Both of them land
    # in the ready room, which is the whole point: whoever was waiting gets the
    # same moment to put their hands on the keyboard as whoever just arrived.
    sign_in bob
    post "/challenges"
    challenge.reload.should be_lobby
    challenge.started_at.should be_nil
    challenge.users.should match_array([ alice, bob ])

    get "/challenges/#{challenge.id}"
    response.body.should include(I18n.t("challenges.found_opponent"))
    response.body.should include(I18n.t("challenges.ready_cta"))

    # One „Готов съм" is not enough to start anything.
    post "/challenges/#{challenge.id}/ready"
    challenge.reload.should be_lobby
    challenge.starts_at.should be_nil
    get "/challenges/#{challenge.id}"
    response.body.should include(I18n.t("challenges.waiting_for_opponent"))

    # The second one starts the countdown, and the match waits it out.
    sign_in alice
    post "/challenges/#{challenge.id}/ready"
    challenge.reload.should be_lobby
    challenge.seconds_to_start.should be_between(1, Challenge::COUNTDOWN_SECONDS)

    get "/challenges/#{challenge.id}/state"
    JSON.parse(response.body)["starts_in"].should be_present

    challenge.update!(starts_at: 1.second.ago)
    get "/challenges/#{challenge.id}"
    challenge.reload.should be_active
    # The clock is the countdown's deadline, not whenever a poll happened to
    # land, so both players get the same number of seconds.
    challenge.started_at.should eq(challenge.starts_at)

    # Bob clears the lot; the match stays live until Alice is done too.
    sign_in bob
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
    challenge = duel!(alice, bob)

    sign_in bob
    get "/challenges/#{challenge.id}"
    challenge.participant_for(bob).reload.question_started_at.should be_present
  end

  it "reports the live state as JSON" do
    challenge = duel!(alice, bob)

    sign_in bob
    get "/challenges/#{challenge.id}/state"

    state = JSON.parse(response.body)
    state["status"].should eq("active")
    state["seconds_left"].should be <= challenge.time_limit_seconds
    state["opponent"]["name"].should eq("alice")
    state["you"]["answered"].should eq(0)
  end

  it "shows an opponent without a nickname anonymously" do
    nameless = create(:user, name: "Иван Иванов", nickname: nil)
    challenge = duel!(nameless, alice)

    sign_in alice
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

    started = duel!(alice, bob)
    started.should be_active

    sign_in alice
    delete "/challenges/#{started.id}"
    started.reload.should be_active
  end

  # Matchmaking used to run only on the button, so two people who each ended up
  # with a lobby of their own never found each other however long they sat
  # there. The poll is what looks now.
  it "brings two players waiting in rooms of their own together, with nobody pressing anything" do
    far = create(:user, nickname: "zoe", elo: alice.elo + ChallengeMatchmaker::MAX_GAP + 200)

    sign_in alice
    post "/challenges"
    mine = Challenge.last

    sign_in far
    post "/challenges"
    theirs = Challenge.last
    theirs.should_not eq(mine)

    [ mine, theirs ].each { |lobby| lobby.update!(created_at: (ChallengeMatchmaker::PATIENCE + 5.seconds).ago) }

    # Their own screen's poll pairs them and tells the page it has moved.
    get "/challenges/#{theirs.id}/state"
    state = JSON.parse(response.body)
    state["status"].should eq("lobby")
    state["redirect"].should eq("/challenges/#{mine.id}")
    theirs.reload.should be_abandoned

    # Alice's poll finds the room she was already in, now full.
    sign_in alice
    get "/challenges/#{mine.id}/state"
    JSON.parse(response.body)["status"].should eq("lobby")
    JSON.parse(response.body)["redirect"].should be_nil
    mine.reload.users.should match_array([ alice, far ])
  end

  it "sends a player whose lobby was merged away to the room they are now in" do
    far = create(:user, elo: alice.elo + ChallengeMatchmaker::MAX_GAP + 200)

    sign_in alice
    post "/challenges"
    mine = Challenge.last
    sign_in far
    post "/challenges"
    theirs = Challenge.last

    [ mine, theirs ].each { |lobby| lobby.update!(created_at: (ChallengeMatchmaker::PATIENCE + 5.seconds).ago) }

    get "/challenges/#{theirs.id}"
    response.should redirect_to("/challenges/#{mine.id}")
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
    challenge = duel!(alice, bob)

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
    challenge = duel!(alice, bob)

    sign_in bob
    get "/challenges/#{challenge.id}"
    post "/challenges/#{challenge.id}/answers",
         params: { challenge_question_id: challenge.challenge_questions.first.id, value: "" }

    flash[:alert].should eq(I18n.t("answers.blank"))
    challenge.participant_for(bob).challenge_answers.should be_empty
  end

  it "shows the duel record and history on the index" do
    challenge = duel!(alice, bob)

    sign_in bob
    answer_everything(challenge, value: "42")
    challenge.update!(started_at: (challenge.time_limit_seconds + 1).seconds.ago)
    get "/challenges/#{challenge.id}"

    get "/challenges"
    response.body.should include(I18n.t("duel.recent"))
    response.body.should include("alice")
    ChallengeRecord.for(bob).won.should eq(1)
  end
end
