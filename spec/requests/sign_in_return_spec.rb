require "rails_helper"

# A link opened while signed out goes on to that page once signed in — it used
# to land on the home page, and a link to a paper led nowhere.
describe "Signing in from a link", type: :request do
  it "goes on to the page that was asked for" do
    student = create(:user, password: "secret123")

    get "/practice/types?from=link"
    response.should redirect_to(sign_in_path)

    sign_in student
    response.should redirect_to("/practice/types?from=link")
  end

  it "lets the team open a competition's papers, which were for students only" do
    admin = create(:user, role: :admin, password: "secret123")
    stub_calendar(competition_event)
    sign_in admin

    get competitions_path
    response.should have_http_status(:ok)
  end
end
