require "rails_helper"

describe "Role authorization", type: :request do
  let(:student) { create(:user) }
  let(:parent) { create(:user, role: :parent, verified_at: Time.current) }

  it "keeps students out of the parent and admin areas" do
    sign_in student

    get "/parents/children"
    response.should redirect_to("/")

    get "/overseer"
    response.should redirect_to("/")
  end

  it "lets a parent manage children but not the admin area" do
    sign_in parent

    get "/parents/children"
    response.should have_http_status(:ok)

    get "/overseer"
    response.should redirect_to("/")
  end

  it "lets an unverified parent work while email confirmation is off" do
    sign_in create(:user, role: :parent)

    post "/parents/children", params: { name: "Мими" }

    User.find_by(name: "Мими").should be_present
  end

  it "blocks unverified parents from mutations but not from browsing, once confirmation is on" do
    allow(Mailing).to receive(:enabled?).and_return(true)
    sign_in create(:user, role: :parent)

    get "/parents/children"
    response.should have_http_status(:ok)

    post "/parents/children", params: { name: "Мими" }
    User.find_by(name: "Мими").should be_nil
    flash[:alert].should be_present
  end

  it "registers any unknown role as a student — teacher included, since the role is gone" do
    post "/sign-up", params: { name: "Мария", email: "m@example.com", password: "secret123", role: "teacher" }

    User.find_by(email: "m@example.com").role.should eq("student")
  end
end

describe "Email verification and password reset", type: :request do
  it "sends no confirmation mail on sign-up while confirmation is off" do
    expect(UserMailer).not_to receive(:email_verification)

    post "/sign-up", params: { name: "Ивана", email: "i@example.com", password: "secret123", role: "parent" }

    User.find_by(email: "i@example.com").should be_present
  end

  it "verifies a user from a valid token and rejects garbage" do
    user = create(:user, role: :parent)

    get "/verify-email/#{user.generate_token_for(:email_verification)}"
    user.reload.verified_at.should be_present

    get "/verify-email/garbage"
    response.should redirect_to("/sign-in")
  end

  it "closes the password reset flow while mail is off" do
    user = create(:user, email: "real@example.com")
    token = user.generate_token_for(:password_reset)
    expect(UserMailer).not_to receive(:password_reset)

    get "/password_resets/new"
    response.should redirect_to("/sign-in")

    post "/password_resets", params: { email: "real@example.com" }
    response.should redirect_to("/sign-in")

    patch "/password_resets/#{token}", params: { password: "brand-new-pass" }
    user.reload.authenticate("brand-new-pass").should be_falsey
  end

  it "keeps the forgotten-password link off the sign-in page while mail is off" do
    get "/sign-in"

    response.body.should_not include(I18n.t("password_reset.forgot"))
  end

  it "resets the password via the emailed token once mail is on" do
    allow(Mailing).to receive(:enabled?).and_return(true)
    user = create(:user)
    token = user.generate_token_for(:password_reset)

    patch "/password_resets/#{token}", params: { password: "brand-new-pass" }

    user.reload.authenticate("brand-new-pass").should be_truthy
  end

  it "responds identically whether the reset email exists or not" do
    allow(Mailing).to receive(:enabled?).and_return(true)
    create(:user, email: "real@example.com")

    post "/password_resets", params: { email: "real@example.com" }
    real_response = response.redirect_url
    post "/password_resets", params: { email: "fake@example.com" }

    response.redirect_url.should eq(real_response)
  end
end
