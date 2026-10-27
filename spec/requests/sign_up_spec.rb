require "rails_helper"

describe "Signing up", type: :request do
  it "creates the account and signs the new user in on a fresh session" do
    session_key = Rails.application.config.session_options[:key]

    get "/sign-up"
    session_before = cookies[session_key]

    post "/sign-up", params: { name: "Нов Ученик", email: "new@example.com", password: "password" }

    # A new student is shown where they stand before anything else.
    response.should redirect_to("/placements/new")
    User.find_by(email: "new@example.com").should be_present
    # Same rule as signing in: a session fixed before the account existed must
    # not ride into it.
    cookies[session_key].should_not eq(session_before)
  end
  # A refused sign-up came back as the same form, empty and without a word,
  # which a parent reported as "the page just refreshed".
  it "says why it refused, keeps what was typed and points a returning parent to adding a child" do
    User.create!(name: "Родител", email: "parent@example.com", password: "secret123", role: :parent)

    post "/sign-up", params: { name: "Митачето", email: "Parent@example.com", password: "secret123", role: "student" }

    response.should have_http_status(:unprocessable_entity)
    response.body.should include("Имейл вече съществува")
    response.body.should include("Семейство")
    response.body.should include(%(value="Митачето"))
    response.body.should_not include("secret123")
  end

  it "names a password that is too short" do
    post "/sign-up", params: { name: "Ива", email: "iva@example.com", password: "123", role: "parent" }

    response.should have_http_status(:unprocessable_entity)
    response.body.should include("Парола е твърде кратко")
    response.body.should include(%(<option selected="selected" value="parent">))
  end
end
