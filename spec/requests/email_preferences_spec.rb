require "rails_helper"

# Which emails to receive: from the link in an email without signing in, and
# from Настройки. See EmailPreferences.
describe "Email preferences", type: :request do
  let(:parent) { create(:user, role: :parent) }
  let(:token) { parent.generate_token_for(:email_preferences) }

  describe "from the link in an email" do
    it "shows every optional email this person can get, and the account emails that always go" do
      get "/emails/#{token}"

      response.should have_http_status(:ok)
      response.body.should include(I18n.t("email_preferences.kinds.weekly_report.title"))
      response.body.should include(I18n.t("email_preferences.always.title"))
    end

    it "saves the switches, and „stop all“ turns every one off" do
      patch "/emails/#{token}", params: { emails: { weekly_report: "0" } }
      parent.reload.weekly_report.should be(false)

      patch "/emails/#{token}", params: { emails: { weekly_report: "1" } }
      parent.reload.weekly_report.should be(true)

      patch "/emails/#{token}", params: { emails: { weekly_report: "1" }, stop_all: "Спри всички" }
      parent.reload.weekly_report.should be(false)
    end

    it "asks first before unsubscribing: opening the link changes nothing, because mail scanners open every link" do
      get "/emails/#{token}/unsubscribe/weekly_report"

      response.should have_http_status(:ok)
      parent.reload.weekly_report.should be(true)
    end

    it "unsubscribes on the button, and on a mail client's one-click POST without a CSRF token" do
      ActionController::Base.allow_forgery_protection = true
      post "/emails/#{token}/unsubscribe/weekly_report"

      parent.reload.weekly_report.should be(false)
      response.should redirect_to("/emails/#{token}")
    ensure
      ActionController::Base.allow_forgery_protection = false
    end

    it "refuses a link that is not one, and an email this person is never sent" do
      post "/emails/nonsense/unsubscribe/weekly_report"
      response.should redirect_to("/sign-in")

      student = create(:user, role: :student)
      get "/emails/#{student.generate_token_for(:email_preferences)}/unsubscribe/weekly_report"
      response.should have_http_status(:not_found)
    end
  end

  describe "in Настройки" do
    before { allow(Mailing).to receive(:enabled?).and_return(true) }

    it "lets a parent switch the weekly report off and on again" do
      sign_in parent

      get "/settings"
      response.body.should include(I18n.t("email_preferences.kinds.weekly_report.title"))

      put "/profile", params: { user: { weekly_report: "0" } }
      parent.reload.weekly_report.should be(false)
    end

    it "offers a student no switch for an email they are never sent, and ignores one posted anyway" do
      student = create(:user, role: :student)
      sign_in student

      get "/settings"
      response.body.should_not include(I18n.t("email_preferences.kinds.weekly_report.title"))
      response.body.should include(I18n.t("email_preferences.always.title"))

      put "/profile", params: { user: { weekly_report: "0" } }
      student.reload.weekly_report.should be(true)
    end
  end
end
