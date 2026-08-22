require "rails_helper"

describe "Signing up", type: :request do
  it "creates the account and signs the new user in on a fresh session" do
    session_key = Rails.application.config.session_options[:key]

    get "/sign-up"
    session_before = cookies[session_key]

    post "/sign-up", params: { name: "Нов Ученик", email: "new@example.com", password: "password" }

    response.should redirect_to("/calendar")
    User.find_by(email: "new@example.com").should be_present
    # Same rule as signing in: a session fixed before the account existed must
    # not ride into it.
    cookies[session_key].should_not eq(session_before)
  end
end
