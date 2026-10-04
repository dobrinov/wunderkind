require "rails_helper"

describe "Choosing who to duel and what about", type: :request do
  # Two categories with real depth, so a restricted match can actually fill.
  let!(:geometry) { Topic.create!(name: "Геометрия") }
  let!(:fractions) { Topic.create!(name: "Дроби") }
  let!(:geometry_leaf) { Topic.create!(name: "Ъгли", parent: geometry) }

  before do
    30.times { |n| create(:question, elo: 900 + (n % 10) * 20).topics << geometry_leaf }
    30.times { |n| create(:question, elo: 900 + (n % 10) * 20).topics << fractions }
  end

  let(:host) { create(:user, elo: 1000, nickname: "Ана") }
  let(:guest) { create(:user, elo: 1020, nickname: "Боян") }

  def open_lobby(user, categories = [])
    ChallengeMatchmaker.call(user: user, topic_ids: Array(categories).map(&:id))
  end

  describe DuelCategories do
    it "offers only the categories this student has problems in" do
      empty = Topic.create!(name: "Тригонометрия")
      create(:question, elo: 2700).topics << empty

      names = DuelCategories.for(host).map(&:name)

      names.should include("Геометрия", "Дроби")
      names.should_not include("Тригонометрия")
    end

    it "stands a category for its leaves, so a question tagged deep still counts" do
      ids = DuelCategories.topic_ids_for([ geometry ])

      ids.should include(geometry.id, geometry_leaf.id)
    end

    it "drops a category the student was never offered rather than refusing" do
      unreachable = Topic.create!(name: "Анализ")

      DuelCategories.selected(host, [ geometry.id, unreachable.id ]).should eq([ geometry.id ])
    end
  end

  describe "opening a room with categories" do
    it "remembers what it is about, and draws the match from it" do
      lobby = open_lobby(host, [ geometry ])
      lobby.topics.should eq([ geometry ])

      ChallengeMatchmaker.join!(lobby.reload, guest)

      lobby.reload.questions.each { |question| question.topics.map(&:id).should include(geometry_leaf.id) }
    end

    it "means anything when nothing was picked" do
      open_lobby(host).topics.should be_empty
    end

    it "refuses a category with nothing behind it at this student's level" do
      thin = Topic.create!(name: "Стереометрия")
      create(:question, elo: 950).topics << thin

      expect { ChallengeMatchmaker.send(:open_lobby, host, [ thin.id ]) }.
        to raise_error(Dispatcher::NotEnoughQuestions)
    end
  end

  describe "being matched without asking" do
    it "does not drop a student into a room about something they did not ask for" do
      open_lobby(host, [ geometry ])

      joined = open_lobby(guest, [ fractions ])

      joined.users.should eq([ guest ])
      joined.topics.should eq([ fractions ])
    end

    it "pairs two players whose categories overlap, on the overlap" do
      open_lobby(host, [ geometry, fractions ])

      joined = open_lobby(guest, [ fractions ])

      joined.users.should match_array([ host, guest ])
      joined.topics.should eq([ fractions ])
    end

    it "lets a student with no preference into any room" do
      lobby = open_lobby(host, [ geometry ])

      joined = open_lobby(guest)

      joined.id.should eq(lobby.id)
      joined.topics.should eq([ geometry ])
    end
  end

  describe "the browser" do
    it "lists who is waiting, their band and what the room is about" do
      open_lobby(host, [ geometry ])

      sign_in guest
      get "/challenges"

      response.body.should include("Ана")
      response.body.should include(RatingBand.new(host.elo).name)
      response.body.should include("Геометрия")
      response.body.should include(I18n.t("duel.join"))
    end

    # Nicknames everywhere an opponent is shown — the leaderboard's stance.
    it "never shows the waiting player's real name" do
      host.update!(name: "Анелия Истинска", nickname: "Ана")
      open_lobby(host, [ geometry ])

      sign_in guest
      get "/challenges"

      response.body.should_not include("Анелия Истинска")
    end

    it "does not list the student their own room" do
      open_lobby(guest)

      sign_in guest
      get "/challenges"

      response.body.should include(I18n.t("duel.lobbies_empty"))
    end

    it "refreshes itself without the page" do
      open_lobby(host, [ geometry ])

      sign_in guest
      get "/challenges/lobbies"

      response.should have_http_status(:ok)
      response.body.should include("Ана")
      response.body.should_not include("<html")
    end

    it "joins the room that was picked, whatever the ratings say" do
      far = create(:user, elo: host.elo + ChallengeMatchmaker::MAX_GAP + 300, nickname: "Далечен")
      lobby = open_lobby(host, [ geometry ])

      sign_in far
      post "/challenges/#{lobby.id}/join"

      lobby.reload.users.should match_array([ host, far ])
      response.should redirect_to(challenge_path(lobby, close_path: challenges_path))
    end

    it "says so plainly when somebody else got there first" do
      lobby = open_lobby(host, [ geometry ])
      ChallengeMatchmaker.join!(lobby, guest)
      latecomer = create(:user, elo: 1000)

      sign_in latecomer
      post "/challenges/#{lobby.id}/join"

      response.should redirect_to(challenges_path)
      flash[:notice].should eq(I18n.t("challenges.lobby_taken"))
      lobby.reload.users.should match_array([ host, guest ])
    end

    it "only offers categories the student can play" do
      Topic.create!(name: "Тригонометрия").tap { |t| create(:question, elo: 2700).topics << t }

      sign_in host
      get "/challenges"

      response.body.should include("Геометрия")
      response.body.should_not include("Тригонометрия")
    end
  end
end
