require "rails_helper"

describe "The duel-invitation switch", type: :request do
  let(:student) { create(:user) }
  let(:subscription) do
    { endpoint: "https://push.example.com/abc", keys: { p256dh: "p256dh-key", auth: "auth-key" } }
  end

  before { sign_in student }

  it "saves this device for the signed-in student, once however often it is sent" do
    2.times { post "/push_subscription", params: { subscription: subscription }, as: :json }

    response.should have_http_status(:ok)
    student.push_subscriptions.pluck(:endpoint).should eq([ "https://push.example.com/abc" ])
  end

  it "says whether this student has this device" do
    get "/push_subscription", params: { endpoint: "https://push.example.com/abc" }
    response.parsed_body["subscribed"].should be(false)

    post "/push_subscription", params: { subscription: subscription }, as: :json
    get "/push_subscription", params: { endpoint: "https://push.example.com/abc" }
    response.parsed_body["subscribed"].should be(true)
  end

  it "turns it off for this student only, leaving a sibling on the same device" do
    sibling = create(:user)
    sibling.push_subscriptions.create!(endpoint: "https://push.example.com/abc", p256dh: "k", auth: "a")
    post "/push_subscription", params: { subscription: subscription }, as: :json

    delete "/push_subscription", params: { endpoint: "https://push.example.com/abc" }, as: :json

    student.push_subscriptions.should be_empty
    sibling.push_subscriptions.count.should eq(1)
  end

  it "refuses an endpoint that is not https" do
    post "/push_subscription", params: { subscription: subscription.merge(endpoint: "http://evil.example/x") }, as: :json

    response.should have_http_status(:unprocessable_content)
  end
end
