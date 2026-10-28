require "rails_helper"

describe "Stopping the weekly report from the email", type: :request do
  let(:parent) { create(:user, role: :parent) }
  let(:path) { "/weekly-report/unsubscribe/#{parent.generate_token_for(:weekly_report_unsubscribe)}" }

  it "asks first: opening the link changes nothing, because mail scanners open every link" do
    get path

    response.should have_http_status(:ok)
    parent.reload.weekly_report.should be(true)
  end

  it "stops it on the button, and on a mail client's one-click POST without a CSRF token" do
    ActionController::Base.allow_forgery_protection = true
    post path

    parent.reload.weekly_report.should be(false)
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  it "refuses a link that is not one" do
    post "/weekly-report/unsubscribe/nonsense"

    response.should redirect_to("/sign-in")
  end

  it "can be turned off and on again in the parent's settings when mail is on" do
    allow(Mailing).to receive(:enabled?).and_return(true)
    sign_in parent

    get "/settings"
    response.body.should include(I18n.t("profile.weekly_report"))

    put "/profile", params: { user: { name: parent.name, weekly_report: "0" } }
    parent.reload.weekly_report.should be(false)
  end
end
