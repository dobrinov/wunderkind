require "rails_helper"

describe "Friends, presence and duel invitations", type: :request do
  let!(:topic) { Topic.create!(name: "E2E") }
  let(:mimi) { create(:user, name: "Мими Истинска", nickname: "mimi", elo: 1000) }
  let(:boyan) { create(:user, name: "Боян Истински", nickname: "boyan", elo: 1030) }

  before { 20.times { |n| create(:question, elo: 950 + n * 5).topics << topic } }

  def befriend!(one, other)
    Friendship.create!(requester: one, addressee: other).tap(&:accept!)
  end

  describe Friends do
    it "adds a friend by the code they handed over, and asks them first" do
      code = boyan.ensure_friend_code!

      result = Friends.request!(mimi, code.downcase)

      result.should be_ok
      result.friendship.should be_pending
      Friends.pending_for(boyan).should eq([ result.friendship ])
      mimi.friends.should be_empty
    end

    it "says which kind of nothing happened" do
      Friends.request!(mimi, "ZZZZZZ").error.should eq(:unknown_code)
      Friends.request!(mimi, mimi.ensure_friend_code!).error.should eq(:yourself)

      Friends.request!(mimi, boyan.ensure_friend_code!)
      Friends.request!(mimi, boyan.friend_code).error.should eq(:already_asked)
    end

    it "refuses the same pair asked the other way round" do
      Friendship.create!(requester: mimi, addressee: boyan)

      Friendship.new(requester: boyan, addressee: mimi).should_not be_valid
    end

    it "makes a friendship read the same from both sides" do
      friendship = befriend!(mimi, boyan)

      mimi.friends.should eq([ boyan ])
      boyan.friends.should eq([ mimi ])
      Friendship.accepted.pick_between(boyan, mimi).should eq(friendship)
    end

    it "puts the friends who are here first" do
      away = create(:user, name: "Ана", nickname: "ana")
      befriend!(mimi, away)
      befriend!(mimi, boyan)
      away.update_column(:last_seen_at, 1.hour.ago)
      boyan.seen!

      Friends.list(mimi).should eq([ boyan, away ])
    end

    # A friend code must never be a way into somebody's account as a parent.
    it "is a different code from the one that links a parent" do
      code = mimi.ensure_friend_code!

      mimi.reload.link_code.should be_nil
      User.find_by(link_code: code).should be_nil
    end
  end

  describe "presence" do
    it "is stamped by looking at a page, and goes stale on its own" do
      sign_in mimi
      get "/calendar"

      mimi.reload.last_seen_at.should be_present
      mimi.should be_online

      mimi.update_column(:last_seen_at, (User::ONLINE_WINDOW + 1.minute).ago)
      mimi.reload.should_not be_online
    end

    it "writes at most once a minute, whatever a page costs" do
      sign_in mimi
      get "/calendar"
      first = mimi.reload.last_seen_at

      get "/calendar"

      mimi.reload.last_seen_at.should eq(first)
    end

    # The child is not at the screen; a green dot beside their name would be
    # saying they are.
    it "is not stamped by an admin looking in" do
      admin = create(:user, role: :admin, verified_at: Time.current)

      sign_in admin
      post "/impersonate/#{mimi.id}"
      get "/calendar"

      mimi.reload.last_seen_at.should be_nil
    end
  end

  describe "the friends page" do
    it "shows the code, the friends and who is here" do
      befriend!(mimi, boyan)
      boyan.seen!

      sign_in mimi
      get "/friends"

      response.body.should include(mimi.reload.friend_code)
      response.body.should include("boyan")
      response.body.should include(I18n.t("friends.online"))
      # Nicknames, like every other screen that shows another child.
      response.body.should_not include("Боян Истински")
    end

    it "carries waiting requests in the nav, so they are not missed" do
      Friendship.create!(requester: boyan, addressee: mimi)

      sign_in mimi
      get "/calendar"

      response.body.should include("#{I18n.t("nav.friends")} (1)")
    end

    it "accepts a request, and only the person it was sent to can" do
      request = Friendship.create!(requester: boyan, addressee: mimi)
      stranger = create(:user)

      sign_in stranger
      patch "/friends/#{request.id}/accept"
      response.should have_http_status(:not_found)
      request.reload.should be_pending

      sign_in mimi
      patch "/friends/#{request.id}/accept"
      request.reload.should be_accepted
    end

    it "removes a friendship from either side" do
      friendship = befriend!(mimi, boyan)

      sign_in boyan
      delete "/friends/#{friendship.id}"

      Friendship.exists?(friendship.id).should be(false)
      mimi.friends.should be_empty
    end

    it "is not a parent's screen" do
      parent = create(:user, role: :parent, verified_at: Time.current)

      sign_in parent
      get "/friends"

      response.should redirect_to("/parents/children")
    end
  end

  describe "inviting a friend to a duel" do
    it "opens a room only that friend can take a seat in" do
      friendship = befriend!(mimi, boyan)
      stranger = create(:user, elo: 1010)

      sign_in mimi
      post "/friends/#{friendship.id}/invite"

      challenge = Challenge.last
      challenge.invited_user.should eq(boyan)
      response.should redirect_to(challenge_path(challenge, close_path: friends_path))

      # Invisible to the queue, and to anybody else looking at the list.
      Challenge.open_lobbies.should_not include(challenge)
      ChallengeMatchmaker.open_lobbies(stranger).should be_empty

      sign_in stranger
      post "/challenges/#{challenge.id}/accept_invite"
      challenge.reload.should be_waiting
      challenge.users.should eq([ mimi ])
    end

    it "is never eaten by matchmaking looking for an opponent" do
      friendship = befriend!(mimi, boyan)
      sign_in mimi
      post "/friends/#{friendship.id}/invite"
      invite = Challenge.last

      # Somebody else presses the button. They must open their own room.
      stranger = create(:user, elo: mimi.elo)
      theirs = ChallengeMatchmaker.call(user: stranger)

      theirs.id.should_not eq(invite.id)
      invite.reload.should be_waiting
      invite.users.should eq([ mimi ])
    end

    it "shows up for the friend and starts the room when accepted" do
      friendship = befriend!(mimi, boyan)
      sign_in mimi
      post "/friends/#{friendship.id}/invite"
      invite = Challenge.last

      sign_in boyan
      get "/challenges"
      response.body.should include(I18n.t("duel.invited_you", name: "mimi"))

      post "/challenges/#{invite.id}/accept_invite"

      invite.reload.should be_lobby
      invite.users.should match_array([ mimi, boyan ])
      invite.questions.size.should eq(Challenge::QUESTION_COUNT)
    end

    it "can be turned down by the friend it was sent to" do
      friendship = befriend!(mimi, boyan)
      sign_in mimi
      post "/friends/#{friendship.id}/invite"
      invite = Challenge.last

      sign_in boyan
      delete "/challenges/#{invite.id}"

      invite.reload.should be_abandoned
    end

    # Fifteen minutes, not three: it is waiting on a person noticing rather
    # than on somebody staring at a searching screen.
    it "waits far longer than a room in the public queue" do
      friendship = befriend!(mimi, boyan)
      sign_in mimi
      post "/friends/#{friendship.id}/invite"
      invite = Challenge.last

      invite.update_column(:created_at, (Challenge::LOBBY_TTL + 1.minute).ago)
      ChallengeMatchmaker.invites_for(boyan).should eq([ invite.reload ])

      invite.update_column(:created_at, (Challenge::INVITE_TTL + 1.minute).ago)
      ChallengeMatchmaker.invites_for(boyan).should be_empty
      invite.reload.should be_abandoned
    end

    it "is played however the two of them chose" do
      friendship = befriend!(mimi, boyan)

      sign_in mimi
      post "/friends/#{friendship.id}/invite",
           params: { question_count: "10", seconds_per_question: "15" }

      challenge = Challenge.last
      challenge.question_count.should eq(10)
      challenge.seconds_per_question.should eq(15)
      # The clock the whole match runs on is the two of them multiplied.
      challenge.time_limit_seconds.should eq(150)
      challenge.should be_custom_format

      # The problems are drawn when the friend takes the seat, not before.
      challenge.questions.should be_empty
      ChallengeMatchmaker.join!(challenge, boyan)
      challenge.reload.questions.size.should eq(10)
    end

    # A fiddled or stale form is not worth an error page; the fallback is an
    # ordinary duel.
    it "falls back to the house format for anything off the menu" do
      friendship = befriend!(mimi, boyan)

      sign_in mimi
      post "/friends/#{friendship.id}/invite",
           params: { question_count: "500", seconds_per_question: "1" }

      challenge = Challenge.last
      challenge.question_count.should eq(Challenge::QUESTION_COUNT)
      challenge.seconds_per_question.should eq(Challenge::SECONDS_PER_QUESTION)
      challenge.should_not be_custom_format
    end

    it "can be about one topic, like a room in the public queue" do
      geometry = Topic.create!(name: "Геометрия")
      # Thick enough to be a category this student is offered at all — see
      # DuelCategories::MINIMUM, which is why a handful would be dropped.
      30.times { |n| create(:question, elo: 950 + n * 3).topics << geometry }
      friendship = befriend!(mimi, boyan)

      sign_in mimi
      post "/friends/#{friendship.id}/invite", params: { topic_ids: [ geometry.id ] }

      challenge = Challenge.last
      challenge.topics.should eq([ geometry ])

      ChallengeMatchmaker.join!(challenge, boyan)
      challenge.reload.questions.each { |question| question.topics.should include(geometry) }
    end

    it "offers the choices on a screen of its own, not on every row" do
      friendship = befriend!(mimi, boyan)

      sign_in mimi
      get "/friends"
      response.body.should_not include(I18n.t("duel_setup.questions"))

      get "/friends/#{friendship.id}/duel"
      response.should have_http_status(:ok)
      response.body.should include(I18n.t("duel_setup.title", name: "boyan"))
      Challenge::QUESTION_COUNTS.each { |n| response.body.should include(I18n.t("duel_setup.questions_option", count: n)) }
      Challenge::SECONDS_PER_QUESTION_OPTIONS.each { |n| response.body.should include(I18n.t("duel_setup.seconds_option", count: n)) }
    end

    it "will not set up a duel with somebody who has not accepted" do
      request = Friendship.create!(requester: mimi, addressee: boyan)

      sign_in mimi
      get "/friends/#{request.id}/duel"

      response.should redirect_to(friends_path)
    end

    it "refuses somebody who is not a friend yet" do
      request = Friendship.create!(requester: mimi, addressee: boyan)

      sign_in mimi
      post "/friends/#{request.id}/invite"

      response.should redirect_to(friends_path)
      Challenge.count.should eq(0)
    end
  end
end
