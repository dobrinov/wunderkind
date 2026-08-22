require "rails_helper"

describe "Listing a day's assignments", type: :request do
  let(:student) { create(:user, elo: 1200) }

  it "shows a given day" do
    sign_in student
    get "/calendar/#{Date.current.iso8601}/assignments"

    response.should have_http_status(:ok)
  end

  # The bare route and hand-typed URLs used to 500 (`nil.to_date`, Date::Error).
  it "defaults to today without a date" do
    sign_in student
    get "/assignments"

    response.should have_http_status(:ok)
  end

  it "defaults to today on a garbled date" do
    sign_in student
    get "/calendar/garbage/assignments"

    response.should have_http_status(:ok)
  end
end
