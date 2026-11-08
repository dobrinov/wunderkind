require "rails_helper"

describe "The health check", type: :request do
  after { HealthController::DRAIN_FILE.delete if HealthController::DRAIN_FILE.exist? }

  it "is up" do
    get "/up"
    response.should have_http_status(:ok)
  end

  # deploy.sh drains the old container this way before stopping it, so Caddy
  # stops sending it requests while it can still answer them.
  it "is down while the container is draining" do
    FileUtils.touch(HealthController::DRAIN_FILE)
    get "/up"
    response.should have_http_status(:internal_server_error)
  end
end
