require "rails_helper"

describe "Daily practice length", type: :request do
  let(:parent) { create(:user, role: :parent, verified_at: Time.current) }
  let(:child) { create(:user, role: :student, name: "Мира") }

  before { ParentLink.create!(parent: parent, child: child) }

  it "starts a new student on the short default" do
    DailyPractice::DEFAULT_MINUTES.should eq(10)
    create(:user).daily_minutes_target.should be_nil
  end

  # On „Какво упражнява", beside the focus, and no longer on the goals tab:
  # how long a session is belongs with what it is about.
  it "lets a parent choose one of the offered lengths for a linked child" do
    sign_in parent
    get parents_child_path(child, tab: "practice")
    response.body.should include(I18n.t("parents.daily_minutes.title"))
    get parents_child_path(child, tab: "goals")
    response.body.should_not include(I18n.t("parents.daily_minutes.title"))

    patch parents_child_daily_minutes_path(child), params: { minutes: 20 }

    response.should redirect_to(parents_child_path(child, tab: "practice", anchor: "daily-minutes"))
    child.reload.daily_minutes_target.should eq(20)
  end

  it "ignores a length that is not on the menu" do
    sign_in parent
    patch parents_child_daily_minutes_path(child), params: { minutes: 120 }

    child.reload.daily_minutes_target.should be_nil
  end

  it "refuses a child the parent is not linked to" do
    stranger = create(:user, role: :student)
    sign_in parent
    patch parents_child_daily_minutes_path(stranger), params: { minutes: 20 }

    response.should have_http_status(:not_found)
    stranger.reload.daily_minutes_target.should be_nil
  end

  it "shows a child with a parent the length without a field, and keeps it theirs to set otherwise" do
    child.update!(daily_minutes_target: 15)
    sign_in child
    get settings_path
    response.body.should include(I18n.t("profile.daily_minutes_by_parent", count: 15))
    response.body.should_not include("user[daily_minutes_target]")

    patch profile_path, params: { user: { daily_minutes_target: 30 } }
    child.reload.daily_minutes_target.should eq(15)

    loner = create(:user, role: :student)
    sign_in loner
    get settings_path
    response.body.should include("user[daily_minutes_target]")
    patch profile_path, params: { user: { daily_minutes_target: 5 } }
    loner.reload.daily_minutes_target.should eq(5)
  end
end
