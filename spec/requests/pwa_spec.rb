require "rails_helper"

describe "The installable app", type: :request do
  it "serves a manifest that browsers accept as installable" do
    get "/manifest.webmanifest"

    response.should have_http_status(:ok)
    manifest = JSON.parse(response.body)
    manifest["short_name"].should eq "Wunderkind"
    manifest["start_url"].should start_with "/"
    manifest["display"].should eq "standalone"
    sizes = manifest["icons"].map { |icon| icon["sizes"] }
    sizes.should include("192x192", "512x512")
    manifest["icons"].should(be_any { |icon| icon["purpose"] == "maskable" })
  end

  it "points at icons that exist" do
    get "/manifest.webmanifest"

    JSON.parse(response.body)["icons"].each do |icon|
      Rails.public_path.join(icon["src"].delete_prefix("/")).should exist
    end
  end

  it "serves the worker from the root, as JavaScript" do
    get "/service-worker.js"

    response.should have_http_status(:ok)
    response.media_type.should eq "text/javascript"
    response.body.should include "/offline.html"
  end

  it "links the manifest from every page" do
    get "/"

    response.body.should include '<link rel="manifest" href="/manifest.webmanifest">'
  end

  it "has an offline page to fall back on" do
    Rails.public_path.join("offline.html").should exist
  end
end
