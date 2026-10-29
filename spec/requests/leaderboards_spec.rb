require "rails_helper"

# The global board lists only players with points this week, ranked among
# themselves, so its count agrees with the home page's card.
RSpec.describe "Leaderboard", type: :request do
  let(:me) { create(:user, role: :student, nickname: "Аз") }
  let(:ahead) { create(:user, role: :student, nickname: "Бърз") }
  let(:idle) { create(:user, role: :student, nickname: "Спящ") }

  def earn(user, amount) = XpEvent.create!(user: user, amount: amount, reason: "answer")

  before { idle }

  it "leaves out students with no points this week" do
    earn(ahead, 40)
    earn(me, 10)
    sign_in me

    get leaderboard_path

    response.body.should include("Бърз", "Аз")
    response.body.should_not include("Спящ")
  end

  it "tells a student with no points yet that they are not on it" do
    earn(ahead, 40)
    sign_in me

    get leaderboard_path

    response.body.should include(I18n.t("leaderboard_page.no_points"))
  end
end
