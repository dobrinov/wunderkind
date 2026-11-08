#!/bin/bash
# Redeploy wunderkind from GitHub with no downtime. Usage: /opt/apps/wunderkind/deploy.sh [branch]
#
# Blue/green (see compose.yaml). Caddy lists both slots and routes only to one
# whose /up answers (conf.d/wunderkind.caddy, checked every second), so no
# Caddy reload is needed — a reload resets a few connections on every site the
# shared Caddy serves. The release starts in the slot that is not live; once
# it is healthy Caddy starts using it, and the old slot is drained before it is
# stopped: tmp/draining makes its /up answer down (HealthController), Caddy
# stops sending it requests within a second, and the ones it has finish.
# Stopping it without draining was tried: Thruster hands SIGTERM to Puma but
# keeps accepting, and answers 502 to whatever arrives while Puma drains. If
# the release never gets healthy, the old slot simply keeps serving.
#
# Migrations still apply on boot (the entrypoint runs db:prepare) — now while
# the old release is serving, so a migration must not break the code before it
# (add a column, deploy, then drop the old one in a later deploy).
set -euo pipefail

cd /opt/apps/wunderkind
BRANCH="${1:-main}"

live=$(cat .live 2>/dev/null || echo wunderkind-web)
if [ "$live" = wunderkind-blue ]; then slot=green; else slot=blue; fi
next="wunderkind-$slot"

echo "==> fetching $BRANCH"
git -C src fetch --prune origin
git -C src checkout -q -B "$BRANCH" "origin/$BRANCH"
echo "    $(git -C src log --oneline -1)"

echo "==> building"
docker build -t wunderkind:latest src

echo "==> starting $next beside $live (entrypoint runs db:prepare, so migrations apply on boot)"
docker rm -f "$next" >/dev/null 2>&1 || true
docker compose up -d --no-deps --force-recreate "$slot"

echo "==> waiting for health"
status=starting
for i in $(seq 1 90); do
  status=$(docker inspect -f '{{.State.Health.Status}}' "$next" 2>/dev/null || echo starting)
  [ "$status" = healthy ] || [ "$status" = unhealthy ] && break
  sleep 2
done
if [ "$status" != healthy ]; then
  echo "    $next is $status — $live keeps serving. Its last log lines:"
  docker logs --tail 40 "$next" 2>&1 | sed 's/^/    /' || true
  docker rm -f "$next" >/dev/null
  exit 1
fi
echo "    healthy"

# Caddy checks every second; give it a few to see the new slot as up.
sleep 3
echo "$next" > .live

if docker inspect "$live" >/dev/null 2>&1; then
  echo "==> draining $live"
  docker exec "$live" touch tmp/draining || true
  sleep 5
  echo "==> stopping $live"
  docker stop -t 30 "$live" >/dev/null
  docker rm "$live" >/dev/null
fi

echo "==> announcing new releases on Discord"
docker exec "$next" bin/rails changelog:announce || echo "    announce failed (deploy is fine)"

docker image prune -f >/dev/null
echo "==> done ($next is live)"
