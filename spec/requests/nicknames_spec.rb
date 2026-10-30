require "rails_helper"

# Without a nickname a student was „Противник" in friend requests, invitations
# and duels — two siblings duelled without knowing it was each other — and
# missing from the weekly board they were leading.
describe "Asking for a nickname before the social pages", type: :request do
  let(:student) { create(:user, nickname: nil) }

  before { sign_in student }

  it "sends a student without one to the question, and back" do
    [ challenges_path, friends_path, leaderboard_path ].each do |path|
      get path
      response.should redirect_to(new_nickname_path(return_to: path))
    end

    post nickname_path, params: { nickname: "Звездичка", return_to: friends_path }
    response.should redirect_to(friends_path)
    student.reload.nickname.should eq("Звездичка")

    get friends_path
    response.should have_http_status(:ok)
  end

  it "asks again for an empty one" do
    post nickname_path, params: { nickname: "  ", return_to: challenges_path }
    response.should have_http_status(:unprocessable_content)
    student.reload.nickname.should be_nil
  end

  it "does not ask a parent" do
    parent = create(:user, role: :parent, nickname: nil, verified_at: Time.current)
    sign_in parent
    get leaderboard_path
    response.should_not redirect_to(new_nickname_path(return_to: leaderboard_path))
  end
end
