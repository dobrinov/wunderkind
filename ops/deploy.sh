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

# One deploy at a time. Two overlapping runs read the same .live, pick the same
# idle slot, and the later one's `docker rm -f` removes the release the earlier
# one has just made live — after it stopped the old one.
exec 9>.deploy.lock
flock -n 9 || { echo "another deploy is running"; exit 1; }

live=$(cat .live 2>/dev/null || true)
# .live missing or empty (a first deploy, a damaged file): ask Docker which slot
# is up rather than assume, because the slot guessed idle is removed below, and
# guessing wrong removes the one that is serving.
if [ "$live" != wunderkind-blue ] && [ "$live" != wunderkind-green ]; then
  live=$(docker ps --format '{{.Names}}' | grep -E '^wunderkind-(blue|green)$' | head -1 || true)
  live=${live:-wunderkind-none}
fi
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
# Written whole or not at all: a half-written .live is the damaged file above.
echo "$next" > .live.tmp && mv .live.tmp .live

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
# The build cache is not an image and nothing else prunes it: it grew by a few
# hundred MB a deploy until it was 48 GB of a 75 GB disk — 40 GB of that in
# one week, so it is capped by size, not age. 5 GB keeps the layers the next
# build will reuse.
docker builder prune -f --max-used-space 5GB >/dev/null
echo "==> done ($next is live)"
