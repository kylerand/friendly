#!/usr/bin/env bash
#
# quick_screenshots.sh — Launch the app on simulator and capture screenshots
# at timed intervals while you manually navigate the app.
#
# Usage:
#   ./scripts/quick_screenshots.sh              # 10 screenshots, 3s apart
#   ./scripts/quick_screenshots.sh 20 5         # 20 screenshots, 5s apart
#   ./scripts/quick_screenshots.sh --continuous  # capture until Ctrl+C
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
SCREENSHOT_DIR="$PROJECT_DIR/screenshots/manual_$TIMESTAMP"

NUM_SHOTS="${1:-10}"
INTERVAL="${2:-3}"
CONTINUOUS=false

if [[ "${1:-}" == "--continuous" ]]; then
  CONTINUOUS=true
  INTERVAL="${2:-3}"
fi

mkdir -p "$SCREENSHOT_DIR"

# Find booted simulator
DEVICE_ID=$(xcrun simctl list devices booted -j 2>/dev/null \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['state'] == 'Booted':
            print(d['udid'])
            sys.exit(0)
" 2>/dev/null || true)

if [[ -z "$DEVICE_ID" ]]; then
  echo "❌ No booted simulator found. Boot one first or use simulator_test.sh"
  exit 1
fi

DEVICE_NAME=$(xcrun simctl list devices -j 2>/dev/null \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$DEVICE_ID':
            print(d['name'])
            sys.exit(0)
" 2>/dev/null || echo "Unknown")

echo "📱 Device: $DEVICE_NAME"
echo "📁 Saving to: $SCREENSHOT_DIR"
echo ""

if $CONTINUOUS; then
  echo "📸 Continuous mode — press Ctrl+C to stop"
  echo "   Capturing every ${INTERVAL}s..."
  echo ""
  COUNT=1
  trap 'echo ""; echo "✅ Captured $((COUNT-1)) screenshots"; echo "📁 $SCREENSHOT_DIR"; exit 0' INT
  while true; do
    NAME="$(printf '%03d' $COUNT).png"
    xcrun simctl io "$DEVICE_ID" screenshot "$SCREENSHOT_DIR/$NAME" 2>/dev/null
    echo "  📸 $NAME"
    COUNT=$((COUNT + 1))
    sleep "$INTERVAL"
  done
else
  echo "📸 Capturing $NUM_SHOTS screenshots, ${INTERVAL}s apart"
  echo "   Navigate the app manually — screenshots will be captured automatically."
  echo ""
  for i in $(seq 1 "$NUM_SHOTS"); do
    NAME="$(printf '%03d' "$i").png"
    xcrun simctl io "$DEVICE_ID" screenshot "$SCREENSHOT_DIR/$NAME" 2>/dev/null
    echo "  📸 $NAME ($i/$NUM_SHOTS)"
    if [[ $i -lt $NUM_SHOTS ]]; then
      sleep "$INTERVAL"
    fi
  done
fi

echo ""
echo "✅ Done! $NUM_SHOTS screenshots saved."
echo "📁 open $SCREENSHOT_DIR"
