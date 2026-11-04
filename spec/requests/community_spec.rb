require "rails_helper"

# /discord: our own address for the Discord invite, which the static error
# pages link to. Discord is 13+, so a signed-in student is not sent on.
RSpec.describe "The Discord link", type: :request do
  around do |example|
    previous = ENV["DISCORD_INVITE_URL"]
    ENV["DISCORD_INVITE_URL"] = "https://discord.gg/example"
    example.run
  ensure
    ENV["DISCORD_INVITE_URL"] = previous
  end

  it "sends a visitor and a parent on to the invite" do
    get discord_path
    expect(response).to redirect_to("https://discord.gg/example")

    sign_in(create(:user, role: :parent))
    get discord_path
    expect(response).to redirect_to("https://discord.gg/example")
  end

  it "tells a student it is a place for grown-ups instead" do
    sign_in(create(:user))
    get discord_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("community.grown_ups_title"))
    expect(response.body).not_to include("discord.gg")
  end

  it "goes home when no invite is configured" do
    ENV["DISCORD_INVITE_URL"] = nil
    get discord_path

    expect(response).to redirect_to(root_path)
  end

  it "is invited to from the error pages and from a competition the app only partly prepares for" do
    expect(File.read(Rails.root.join("public/404.html"))).to include(%(href="/discord"))
    expect(File.read(Rails.root.join("public/500.html"))).to include(%(href="/discord"))

    stub_calendar(competition_event(slug: "test-olimpiada", style: "proof", name: "Тестова олимпиада"))
    get "/sastezaniya/test-olimpiada"
    expect(response.body).to include(discord_path, I18n.t("community.nudge_link"))
  end
end
