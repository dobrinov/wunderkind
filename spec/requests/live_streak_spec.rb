require "rails_helper"

# users.current_streak is only rewritten on the next practice, so every screen
# reads User#live_streak instead — a child back after two weeks should not be
# greeted with the number they stopped at.
describe "The streak a student is shown", type: :request do
  it "is the live one, not the number they stopped at" do
    student = create(:user, current_streak: 5, last_active_on: 10.days.ago.to_date, streak_freezes: 0)
    sign_in student

    get "/calendar"
    response.body.should_not include("🔥 5")
    response.body.should include("🔥 #{I18n.t("profile.streak_days", count: 0)}")

    get "/profile"
    response.body.should include("🔥 0")
  end

  it "still shows a streak that is alive" do
    student = create(:user, current_streak: 5, last_active_on: Date.yesterday)
    sign_in student

    get "/calendar"
    response.body.should include("🔥 5")
  end
end
