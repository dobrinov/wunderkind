#!/usr/bin/env bash
# Rasterizes the figure SVGs listed in a manifest to the PNGs the question
# importer attaches.
#
#   tools/authoring/rasterize.sh [manifest]     (default tmp/authoring/manifest.tsv)
#
# Manifest columns: svg path, png path, logical width, logical height.
#
# Headless Chrome does the rendering (it is already on the machine, shipped with
# agent-browser's Playwright browsers, and unlike ImageMagick it needs no SVG
# delegate and has the system fonts for Cyrillic labels). ImageMagick then
# quantizes the result to a 32-colour palette: the figures are flat colour, so
# this cuts a 16 KB screenshot to about 5 KB with no visible loss.
set -euo pipefail

MANIFEST="${1:-tmp/authoring/manifest.tsv}"
SCALE="${SCALE:-2}"
JOBS="${JOBS:-8}"

if [ ! -s "$MANIFEST" ]; then
  echo "No figures to rasterize ($MANIFEST is empty)."
  exit 0
fi

CHROME="${CHROME:-}"
if [ -z "$CHROME" ]; then
  CHROME=$(ls -d "$HOME"/Library/Caches/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell 2>/dev/null | sort -V | tail -1 || true)
fi
if [ -z "$CHROME" ] || [ ! -x "$CHROME" ]; then
  echo "No headless Chrome found. Install agent-browser's browsers (agent-browser install) or set CHROME=/path/to/chrome." >&2
  exit 1
fi

render_one() {
  svg="$1"; png="$2"; w="$3"; h="$4"
  mkdir -p "$(dirname "$png")"
  "$CHROME" --headless --disable-gpu --no-sandbox --hide-scrollbars \
    --force-device-scale-factor="$SCALE" --default-background-color=ffffffff \
    --window-size="$w,$h" --screenshot="$png" "file://$(cd "$(dirname "$svg")" && pwd)/$(basename "$svg")" >/dev/null 2>&1
  if [ ! -s "$png" ]; then
    echo "failed: $svg" >&2
    return 1
  fi
  magick "$png" -strip -colors 32 "PNG8:$png"
}
# Batches of $JOBS at a time: `wait -n` is not in the bash that ships with
# macOS, so each batch is waited out in full before the next starts.
running=0
while IFS=$'\t' read -r svg png w h; do
  [ -n "$svg" ] || continue
  render_one "$svg" "$png" "$w" "$h" &
  running=$((running + 1))
  if [ "$running" -ge "$JOBS" ]; then
    wait
    running=0
  fi
done < "$MANIFEST"
wait

count=$(wc -l < "$MANIFEST" | tr -d ' ')
echo "Rasterized $count figures (scale ${SCALE}x)."
