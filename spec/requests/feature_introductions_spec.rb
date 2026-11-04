require "rails_helper"

describe "Features arriving one at a time", type: :request do
  let(:student) { create(:user, toured_at: Time.current, nickname: nil) }

  def ready_for_duels!
    FeatureVisibility::SESSIONS_FOR_DUEL.times { Assignment.create!(user: student, completed_at: Time.current) }
  end

  it "gives a just-placed student the tour on „Днес“, once" do
    student.update!(toured_at: nil, placed_at: Time.current)
    sign_in student

    get home_path
    response.body.should include(%(data-controller="tour"), I18n.t("tour.hero.title"))

    patch tour_path
    response.should have_http_status(:no_content)
    get home_path
    response.body.should_not include(%(data-controller="tour"))
  end

  it "offers duels as a row, introduces them once, and asks for a nickname on the way" do
    ready_for_duels!
    student.update!(introduced_features: [ "badges" ]) # the finished sessions' coin has its own sheet, first
    sign_in student

    get practice_path
    response.body.should include(I18n.t("practice_page.duel_sub"))

    get home_path # shows the coin the finished sessions minted; a sheet waits for the next visit
    response.body.should_not include("intro-dialog")
    get home_path
    response.body.should include("intro-dialog", I18n.t("introductions.duel.title"), I18n.t("introductions.duel.nickname"))

    patch introduction_path("duel"), params: { nickname: "Звездичка", go: "1" }
    response.should redirect_to(challenges_path)
    student.reload.nickname.should eq("Звездичка")
    student.introduced_features.should include("duel")

    get home_path
    response.body.should_not include(I18n.t("introductions.duel.title"))
  end

  it "lets „по-късно“ answer the sheet without going anywhere" do
    ready_for_duels!
    sign_in student

    patch introduction_path("duel")

    response.should redirect_to(home_path)
    student.reload.introduced_features.should include("duel")
  end

  it "shows no second sheet on the visit that answered the first" do
    ready_for_duels!
    BadgeAward.create!(user: student, badge_key: "learned", rung: 1, seen_at: Time.current)
    sign_in student

    get home_path # the coin the finished sessions minted comes first
    get home_path
    response.body.should include(I18n.t("introductions.badges.title"))

    patch introduction_path("badges")
    follow_redirect!
    response.body.should_not include("intro-dialog")

    get home_path
    response.body.should include(I18n.t("introductions.duel.title"))
  end

  it "holds the sheet back while today's session is half done" do
    ready_for_duels!
    daily = Assignment.create!(user: student, kind: :daily)
    daily.assignment_questions.create!(question: create(:question), position: 1)
    sign_in student

    get home_path

    response.body.should_not include("intro-dialog")
  end

  it "keeps everything findable on „Аз“" do
    sign_in student
    get profile_path

    response.body.should include(I18n.t("profile.more.title"), challenges_path, friends_path, competitions_path, new_suggestion_path)
  end

  it "refuses a feature that does not exist" do
    sign_in student
    patch introduction_path("teleport")

    response.should have_http_status(:not_found)
  end

  describe "a parent" do
    let(:parent) { create(:user, role: :parent, verified_at: Time.current) }

    it "can show a child everything at once" do
      ParentLink.create!(parent: parent, child: student)
      sign_in parent

      patch parents_child_features_path(student), params: { show_all: "1" }

      student.reload.should be_show_all_features
      response.should redirect_to(parents_child_path(student, tab: "goals", anchor: "features"))
    end

    it "is walked from an empty family to the child's practice settings" do
      sign_in parent
      get parents_children_path
      response.body.should include(I18n.t("parents.welcome.title"), new_parents_child_path)

      post parents_children_path, params: { name: "Мира" }
      child = parent.reload.managed_children.last

      response.should redirect_to(parents_child_path(child, tab: "practice", welcome: 1))
      follow_redirect!
      response.body.should include(I18n.t("parents.welcome.step_two_title", name: "Мира"), switch_child_path(child))
    end
  end
end
