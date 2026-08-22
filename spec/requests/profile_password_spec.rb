require "rails_helper"

describe "Changing your password from the profile", type: :request do
  def change_password(current: "secret123", password: "brand-new-pass", confirmation: nil)
    patch "/profile/password", params: {
      current_password: current,
      password: password,
      password_confirmation: confirmation.nil? ? password : confirmation
    }
  end

  it "changes the password and keeps the session signed in" do
    user = create(:user)
    sign_in user

    change_password

    user.reload.authenticate("brand-new-pass").should be_truthy
    response.should redirect_to("/profile")
    get "/profile"
    response.should have_http_status(:ok)
  end

  it "refuses a wrong current password" do
    user = create(:user)
    sign_in user

    change_password(current: "not-my-password")

    user.reload.authenticate("secret123").should be_truthy
    flash[:alert].should eq(I18n.t("profile_password.wrong_current"))
  end

  it "refuses a blank new password rather than silently changing nothing" do
    user = create(:user)
    sign_in user

    change_password(password: "")

    user.reload.authenticate("secret123").should be_truthy
    flash[:alert].should eq(I18n.t("profile_password.blank"))
  end

  it "refuses a new password shorter than the model would accept" do
    user = create(:user)
    sign_in user

    change_password(password: "abc")

    user.reload.authenticate("secret123").should be_truthy
    flash[:alert].should eq(I18n.t("profile_password.too_short", count: User::MINIMUM_PASSWORD_LENGTH))
  end

  it "refuses a confirmation that does not match, because a typo is unrecoverable" do
    user = create(:user)
    sign_in user

    change_password(password: "brand-new-pass", confirmation: "brand-new-pasz")

    user.reload.authenticate("secret123").should be_truthy
    flash[:alert].should eq(I18n.t("profile_password.mismatch"))
  end

  it "changes nobody's password while a child's profile is open" do
    parent = create(:user, role: :parent, verified_at: Time.current)
    sign_in parent
    post "/parents/children", params: { name: "Мими" }
    child = parent.managed_children.sole
    post "/switch-child/#{child.id}"

    change_password

    parent.reload.authenticate("secret123").should be_truthy
    child.reload.authenticate("brand-new-pass").should be_falsey
    flash[:alert].should eq(I18n.t("profile_password.child_session"))
  end

  it "offers the form on your own profile but not on a child's" do
    parent = create(:user, role: :parent, verified_at: Time.current)
    sign_in parent
    post "/parents/children", params: { name: "Мими" }

    get "/profile"
    response.body.should include(I18n.t("profile_password.title"))

    post "/switch-child/#{parent.managed_children.sole.id}"
    get "/profile"
    response.body.should_not include(I18n.t("profile_password.title"))
  end

  it "says there is no email recovery while mail is off" do
    sign_in create(:user)

    get "/profile"

    response.body.should include(I18n.t("profile_password.no_recovery"))
  end
end
