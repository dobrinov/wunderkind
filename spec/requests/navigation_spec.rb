require "rails_helper"

# The one menu: the same four places in the header and the phone's tab bar,
# everything else behind the avatar, friends and the leaderboard as tabs of
# the duel, and a parent's managed children one tap away from any screen.
describe "Navigation", type: :request do
  let(:student) { create(:user, elo: 1200) }

  # The home page was /calendar while it held a month grid; bookmarks and
  # home-screen shortcuts made then must still land.
  it "sends the old /calendar addresses to the home page for good" do
    get "/calendar"
    response.should have_http_status(:moved_permanently)
    response.should redirect_to("/home")

    get "/calendar/2026-10-01/assignments"
    response.should redirect_to("/home/2026-10-01/assignments")
  end

  it "sends a parent who opens the student home page to their own" do
    sign_in create(:user, role: :parent)
    get "/home"

    response.should redirect_to(parents_children_path)
  end

  describe "a student's menu" do
    it "starts a new student on three places, without „Двубой“" do
      sign_in student
      get "/home"

      %w[nav.home nav.practice nav.me].each do |key|
        response.body.scan("<span>#{I18n.t(key)}</span>").length.should eq(2)
      end
      response.body.should_not include("<span>#{I18n.t("nav.duel")}</span>")
    end

    it "lists the same four places in the header and the tab bar, in the same words" do
      student.update!(show_all_features: true)
      sign_in student
      get "/home"

      %w[nav.home nav.practice nav.duel nav.me].each do |key|
        response.body.scan("<span>#{I18n.t(key)}</span>").length.should eq(2)
      end
      response.body.scan(%(href="#{practice_path}")).length.should eq(2)
      response.body.should include(%(href="/home">#{I18n.t("app_name")}</a>))
      response.body.should_not include(">#{I18n.t("nav.leaderboard")}<")
    end

    it "keeps settings, suggestions, the changelog and signing out behind the avatar" do
      sign_in student
      get "/home"

      menu = response.body[/<div id="account-menu".*?<\/div>\s*<\/div>\s*<\/div>/m]
      menu.should include(settings_path, suggestions_path, changelog_path, sign_out_path)
    end
  end

  describe "settings" do
    it "carries the account forms, which the profile no longer does" do
      sign_in student

      get "/settings"
      response.body.should include(I18n.t("settings.groups.profile"), I18n.t("profile_password.title"))

      get "/profile"
      response.body.should_not include(I18n.t("profile_password.title"))
    end

    it "is where saving the profile lands" do
      sign_in student
      put "/profile", params: { user: { nickname: "lisi" } }

      response.should redirect_to(settings_path)
      student.reload.nickname.should eq("lisi")
    end
  end

  describe "the duel's tabs" do
    it "puts rooms, friends and the leaderboard on each of the three pages" do
      sign_in student

      [ "/challenges", "/friends", "/leaderboard" ].each do |path|
        get path
        response.body.should include(%(href="#{friends_path}"), %(href="#{leaderboard_path}"))
        response.body.should include(%(class="is-active" aria-current="page"))
      end
    end
  end

  describe "the student home" do
    it "offers the mistakes list once there is a pile to clear, not for one mistake" do
      assignment = Assignment.create!(user: student)
      answer_wrong = lambda do |position|
        aq = assignment.assignment_questions.create!(question: create(:question, answer: "42"), position: position)
        AnswerSubmission.call(assignment_question: aq, user: student, raw: { value: "1" })
      end
      answer_wrong.(1)

      sign_in student
      get "/home"
      response.body.should_not include(I18n.t("home.review_waiting", count: 1))

      (2..FeatureVisibility::REVIEW_CARD_AT).each { |position| answer_wrong.(position) }
      get "/home"
      response.body.should include(I18n.t("home.review_waiting", count: FeatureVisibility::REVIEW_CARD_AT), review_path)
    end

    it "names a friend who is waiting with an invitation" do
      topic = Topic.create!(name: "Дуели")
      20.times { |n| create(:question, elo: 1150 + n * 5).topics << topic }
      host = create(:user, nickname: "boyan", elo: 1200)
      friendship = Friendship.create!(requester: host, addressee: student).tap(&:accept!)
      sign_in host
      post "/friends/#{friendship.id}/invite"

      sign_in student
      get "/home"

      response.body.should include(I18n.t("duel.invited_you", name: "boyan"))
    end
  end

  describe "a parent's header" do
    let(:parent) { create(:user, role: :parent, verified_at: Time.current) }

    it "offers every managed child from any screen, and not while one is open" do
      child = User.create_managed_child!(parent: parent, name: "Мими")

      sign_in parent
      get "/suggestions"
      response.body.should include(I18n.t("nav.who_practises"), switch_child_path(child))

      post "/switch-child/#{child.id}"
      get "/home"
      response.body.should_not include(I18n.t("nav.who_practises"))
    end
  end
end
