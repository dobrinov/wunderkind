# /up, which Docker's healthcheck and the shared Caddy's active health check
# both ask. The one thing it adds to Rails' own: while tmp/draining exists it
# answers down, which is how a deploy takes the old container out of Caddy's
# rotation before stopping it (/opt/apps/wunderkind/deploy.sh). Stopping it
# outright was not enough — Thruster hands SIGTERM to Puma but keeps
# accepting, and answers 502 to everything that arrives while Puma drains.
class HealthController < Rails::HealthController
  DRAIN_FILE = Rails.root.join("tmp/draining")

  def show
    DRAIN_FILE.exist? ? render_down : render_up
  end
end
