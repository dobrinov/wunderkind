# ops/ — what runs on wunderkind.bg

Copies of the deploy files that live on the production host. **The host is
where they run**: deploy.sh never reads this directory, so changing a file
here changes nothing until it is copied over. Keep the two in step — edit
here, install, commit.

| here                     | on the host                                   |
|--------------------------|-----------------------------------------------|
| `deploy.sh`              | `/opt/apps/wunderkind/deploy.sh` (mode 700)   |
| `compose.yaml`           | `/opt/apps/wunderkind/compose.yaml` (mode 600)|
| `rails`                  | `/opt/apps/wunderkind/rails` (mode 700)       |
| `caddy/wunderkind.caddy` | `/opt/infra/caddy/conf.d/wunderkind.caddy`    |

    scp ops/deploy.sh ops/compose.yaml ops/rails root@wunderkind.bg:/opt/apps/wunderkind/
    scp ops/caddy/wunderkind.caddy root@wunderkind.bg:/opt/infra/caddy/conf.d/
    ssh root@wunderkind.bg 'docker exec caddy caddy reload --config /etc/caddy/Caddyfile'

Reload Caddy only after changing its file: a reload resets a few new
connections on every site the shared Caddy serves.

## How a deploy works

Blue/green, with no downtime. Two slots, `wunderkind-blue` and
`wunderkind-green`; `/opt/apps/wunderkind/.live` names the one serving. Caddy
lists both and routes only to one whose `/up` answers (checked every second).
`deploy.sh` builds the image, starts the release in the idle slot, waits for
its healthcheck, then drains the old slot — `tmp/draining` makes its `/up`
answer down (`app/controllers/health_controller.rb`) — and stops it. A release
that never gets healthy never takes traffic. Migrations apply on boot while
the old release still serves, so they must not break the code before them.

`rails` runs `bin/rails` in the live slot; the root crontab uses it for
`reports:weekly` and `reminders:children`.

## Not here

- `/opt/apps/wunderkind/.env` — the secrets.
- `/opt/infra/caddy/Caddyfile` — shared by every site on the host. Its global
  options send the logger `http.handlers.reverse_proxy.health_checker.active`
  to `/data/health-checks.log` instead of the docker log, because the idle
  slot fails a health check every second.
- `/opt/infra/README.md` — the host's own layout notes.
