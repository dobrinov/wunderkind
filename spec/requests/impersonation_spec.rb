require "rails_helper"

describe "Viewing the app as another user", type: :request do
  let(:admin) { create(:user, role: :admin) }
  let(:student) { create(:user, name: "Мими", role: :student) }

  it "puts the admin in the student's seat, visibly, and brings them back" do
    sign_in admin
    post "/impersonate/#{student.id}"

    response.should redirect_to("/calendar")

    get "/calendar"
    response.should have_http_status(:ok)
    response.body.should include(I18n.t("impersonation.viewing_as"))
    response.body.should include(student.name)
    response.body.should include("impersonation-frame")
    response.body.should include(I18n.t("impersonation.stop"))

    # The student's own screens, read as the student would read them.
    get "/profile"
    response.body.should include(student.name)

    # And the admin's are closed, which is the point of standing here.
    get "/overseer/questions"
    response.should redirect_to("/")

    delete "/impersonate"
    response.should redirect_to("/overseer/users")
    get "/overseer/questions"
    response.should have_http_status(:ok)
  end

  it "refuses to write anything while the view is open" do
    sign_in admin
    post "/impersonate/#{student.id}"

    patch "/profile", params: { user: { nickname: "мимиче" } }

    response.should have_http_status(:redirect)
    student.reload.nickname.should be_nil
    flash[:alert].should eq(I18n.t("impersonation.blocked"))
  end

  it "refuses a write posted as JSON without following a redirect into it" do
    sign_in admin
    post "/impersonate/#{student.id}"

    post "/questions/1/answer", params: { value: "42" }, as: :json

    response.should have_http_status(:forbidden)
  end

  it "still lets the admin stop, and sign out, from inside the view" do
    sign_in admin
    post "/impersonate/#{student.id}"

    delete "/sign-out"
    response.should redirect_to("/sign-in")

    get "/calendar"
    response.should redirect_to("/sign-in")
  end

  # The read-only rule is on the verb, and the duel screens are the one place
  # where a GET writes — serving a problem starts the player's clock, and
  # opening a settled match is what finalizes it.
  it "does not start a student's duel clock by looking at their match" do
    opponent = create(:user)
    create_list(:question, Challenge::QUESTION_COUNT, answer: "42", elo: 1000)

    ChallengeMatchmaker.call(user: student)
    challenge = ChallengeMatchmaker.call(user: opponent)
    challenge.should be_active

    participant = challenge.participant_for(student)
    participant.update!(question_started_at: nil)

    sign_in admin
    post "/impersonate/#{student.id}"
    get "/challenges/#{challenge.id}"

    response.should have_http_status(:ok)
    participant.reload.question_started_at.should be_nil
  end

  it "will not view an admin account, nor nest a second view" do
    other_admin = create(:user, role: :admin)

    sign_in admin
    post "/impersonate/#{other_admin.id}"

    flash[:alert].should eq(I18n.t("impersonation.no_admins"))
    get "/overseer/users"
    response.body.should_not include("impersonation-frame")
  end

  it "is closed to everyone who is not an admin" do
    parent = create(:user, role: :parent)

    sign_in parent
    post "/impersonate/#{student.id}"

    flash[:alert].should eq(I18n.t("impersonation.not_allowed"))
    get "/calendar"
    response.body.should_not include("impersonation-frame")
  end

  it "composes with child profiles: a viewed parent can still be stepped into" do
    parent = create(:user, role: :parent, verified_at: Time.current)
    child = User.create_managed_child!(parent: parent, name: "Тошо")

    sign_in admin
    post "/impersonate/#{parent.id}"
    post "/switch-child/#{child.id}"

    get "/calendar"
    response.body.should include(I18n.t("impersonation.viewing_as"))
    response.body.should include(parent.name)
    response.body.should include(I18n.t("child_session.acting_as", name: child.name))

    # Stopping drops the open profile with it, rather than handing it on.
    delete "/impersonate"
    get "/overseer/users"
    response.should have_http_status(:ok)
  end

  it "hands the browser back if the account being viewed is deleted under it" do
    sign_in admin
    post "/impersonate/#{student.id}"

    student.destroy!

    get "/calendar"
    response.should redirect_to("/overseer/users")
    flash[:alert].should eq(I18n.t("impersonation.gone"))

    get "/overseer/users"
    response.should have_http_status(:ok)
    response.body.should_not include("impersonation-frame")
  end

  it "closes the session outright if the admin behind it stops being one" do
    sign_in admin
    post "/impersonate/#{student.id}"

    admin.update!(role: :parent)

    get "/calendar"
    response.should redirect_to("/sign-in")

    # Not merely bounced to the sign-in page — the borrowed session is gone.
    get "/profile"
    response.should redirect_to("/sign-in")
  end
end
