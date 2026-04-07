#!/usr/bin/env bash
#
# simulator_test.sh — Run the Friendly app on an iOS Simulator,
# execute integration tests, and capture screenshots.
#
# Usage:
#   ./scripts/simulator_test.sh                      # auto-pick simulator
#   ./scripts/simulator_test.sh <SIMULATOR_UDID>     # use specific simulator
#   ./scripts/simulator_test.sh --list               # list available simulators
#
# Environment variables (optional):
#   FRIENDLY_TEST_EMAIL     — test account email for automated login
#   FRIENDLY_TEST_PASSWORD  — test account password for automated login
#   (Passed to Flutter via --dart-define)
#
# Output:
#   screenshots/<timestamp>/  — captured screenshots
#   test_report_<timestamp>.log — test log
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
SCREENSHOT_DIR="$PROJECT_DIR/screenshots/$TIMESTAMP"
LOG_FILE="$PROJECT_DIR/screenshots/test_report_${TIMESTAMP}.log"

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log()  { echo -e "${BLUE}[TEST]${NC} $*" | tee -a "$LOG_FILE"; }
ok()   { echo -e "${GREEN}  ✓${NC} $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $*" | tee -a "$LOG_FILE"; }
err()  { echo -e "${RED}  ✗${NC} $*" | tee -a "$LOG_FILE"; }

# ── Setup ───────────────────────────────────────────────────────────────────
mkdir -p "$SCREENSHOT_DIR"
: > "$LOG_FILE"

log "Friendly Pre-Deployment Test Suite"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "Timestamp: $TIMESTAMP"
log "Project:   $PROJECT_DIR"
log "Output:    $SCREENSHOT_DIR"
echo "" >> "$LOG_FILE"

# ── List simulators ────────────────────────────────────────────────────────
list_simulators() {
  echo -e "${CYAN}Available iPhone simulators:${NC}"
  xcrun simctl list devices available | grep -E "iPhone|iPad" | while read -r line; do
    echo "  $line"
  done
}

if [[ "${1:-}" == "--list" ]]; then
  list_simulators
  exit 0
fi

# ── Pick simulator ──────────────────────────────────────────────────────────
DEVICE_ID="${1:-}"

if [[ -z "$DEVICE_ID" ]]; then
  # Try to find a booted simulator first
  DEVICE_ID=$(xcrun simctl list devices booted -j 2>/dev/null \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['state'] == 'Booted' and ('iPhone' in d['name'] or 'iPad' in d['name']):
            print(d['udid'])
            sys.exit(0)
" 2>/dev/null || true)

  if [[ -z "$DEVICE_ID" ]]; then
    # Pick first available iPhone
    DEVICE_ID=$(xcrun simctl list devices available -j 2>/dev/null \
      | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['isAvailable'] and 'iPhone' in d['name']:
            print(d['udid'])
            sys.exit(0)
" 2>/dev/null || true)
  fi
fi

if [[ -z "$DEVICE_ID" ]]; then
  err "No simulator found. Run with --list to see available devices."
  exit 1
fi

# Get device name
DEVICE_NAME=$(xcrun simctl list devices -j 2>/dev/null \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$DEVICE_ID':
            print(d['name'])
            sys.exit(0)
print('Unknown')
" 2>/dev/null || echo "Unknown")

log "Simulator: $DEVICE_NAME ($DEVICE_ID)"

# ── Boot simulator if needed ───────────────────────────────────────────────
DEVICE_STATE=$(xcrun simctl list devices -j 2>/dev/null \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$DEVICE_ID':
            print(d['state'])
            sys.exit(0)
" 2>/dev/null || echo "Unknown")

if [[ "$DEVICE_STATE" != "Booted" ]]; then
  log "Booting simulator..."
  xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
  # Open Simulator.app so the screen is visible
  open -a Simulator --args -CurrentDeviceUDID "$DEVICE_ID" 2>/dev/null || true
  sleep 5
  ok "Simulator booted"
else
  ok "Simulator already running"
fi

# ── Pre-flight checks ──────────────────────────────────────────────────────
log ""
log "Pre-flight checks"
log "─────────────────"

cd "$PROJECT_DIR"

# Check Flutter
if command -v flutter &>/dev/null; then
  FLUTTER_VER=$(flutter --version 2>&1 | head -1)
  ok "Flutter: $FLUTTER_VER"
else
  err "Flutter not found in PATH"
  exit 1
fi

# Check credentials
if [[ -n "${FRIENDLY_TEST_EMAIL:-}" && -n "${FRIENDLY_TEST_PASSWORD:-}" ]]; then
  ok "Test credentials configured"
else
  warn "No test credentials — set FRIENDLY_TEST_EMAIL and FRIENDLY_TEST_PASSWORD for full walkthrough"
fi

# ── Phase 1: Build check ───────────────────────────────────────────────────
log ""
log "Phase 1: Build verification"
log "───────────────────────────"

log "Running flutter pub get..."
flutter pub get --no-example >> "$LOG_FILE" 2>&1
ok "Dependencies resolved"

log "Analyzing code..."
ANALYZE_OUT=$(flutter analyze --no-pub 2>&1 || true)
ISSUE_COUNT=$(echo "$ANALYZE_OUT" | grep -c "info \|warning \|error " || true)
if echo "$ANALYZE_OUT" | grep -q "error •"; then
  err "Static analysis found errors:"
  echo "$ANALYZE_OUT" | grep "error •" | head -5 | tee -a "$LOG_FILE"
else
  ok "Static analysis passed ($ISSUE_COUNT info/warnings)"
fi

# ── Phase 2: Integration test with screenshots ─────────────────────────────
log ""
log "Phase 2: Integration test & screenshots"
log "────────────────────────────────────────"

log "Building and running integration test on $DEVICE_NAME..."
log "(This may take a few minutes on first run)"

DART_DEFINES=""
if [[ -n "${FRIENDLY_TEST_EMAIL:-}" && -n "${FRIENDLY_TEST_PASSWORD:-}" ]]; then
  DART_DEFINES="--dart-define=TEST_EMAIL=${FRIENDLY_TEST_EMAIL} --dart-define=TEST_PASSWORD=${FRIENDLY_TEST_PASSWORD}"
fi

# Start video recording BEFORE the test so it captures the full walkthrough
VIDEO_PATH="$SCREENSHOT_DIR/app_recording.mp4"
xcrun simctl io "$DEVICE_ID" recordVideo --codec=h264 --force "$VIDEO_PATH" &
VIDEO_PID=$!
log "📹 Video recording started (PID $VIDEO_PID)"

INTEGRATION_EXIT=0
flutter test integration_test/app_test.dart \
  -d "$DEVICE_ID" \
  $DART_DEFINES \
  2>&1 | tee -a "$LOG_FILE" || INTEGRATION_EXIT=$?

if [[ $INTEGRATION_EXIT -eq 0 ]]; then
  ok "Screenshot walkthrough passed"
else
  warn "Screenshot walkthrough exited with code $INTEGRATION_EXIT"
fi

# ── Phase 2b: Feature tests ───────────────────────────────────────────────
log ""
log "Phase 2b: Feature tests"
log "───────────────────────"

FEATURE_EXIT=0
flutter test integration_test/feature_test.dart \
  -d "$DEVICE_ID" \
  $DART_DEFINES \
  2>&1 | tee -a "$LOG_FILE" || FEATURE_EXIT=$?

# Stop video recording — SIGINT lets simctl finalize the MP4 properly
kill -INT "$VIDEO_PID" 2>/dev/null || true
sleep 2
wait "$VIDEO_PID" 2>/dev/null || true

if [[ -f "$VIDEO_PATH" ]]; then
  VIDEO_SIZE=$(du -h "$VIDEO_PATH" | cut -f1)
  ok "Video recorded: app_recording.mp4 ($VIDEO_SIZE)"
else
  warn "Video recording failed"
fi

if [[ $FEATURE_EXIT -eq 0 ]]; then
  ok "Feature tests passed"
else
  warn "Feature tests exited with code $FEATURE_EXIT (check log for details)"
fi

# Use worst exit code
if [[ $INTEGRATION_EXIT -ne 0 ]]; then
  INTEGRATION_EXIT=$INTEGRATION_EXIT
elif [[ $FEATURE_EXIT -ne 0 ]]; then
  INTEGRATION_EXIT=$FEATURE_EXIT
fi

# ── Phase 3: Simulator screenshots (simctl) ────────────────────────────────
log ""
log "Phase 3: Simulator screenshots (simctl)"
log "────────────────────────────────────────"

capture_simctl_screenshot() {
  local name="$1"
  local path="$SCREENSHOT_DIR/simctl_${name}.png"
  if xcrun simctl io "$DEVICE_ID" screenshot "$path" 2>/dev/null; then
    ok "Captured: simctl_${name}.png"
  else
    warn "Failed to capture: $name"
  fi
}

capture_simctl_screenshot "final_state"

# ── Summary ─────────────────────────────────────────────────────────────────
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "Test run complete!"
log ""

# Count screenshots
SHOT_COUNT=$(find "$SCREENSHOT_DIR" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
log "📸 File screenshots: $SHOT_COUNT"
log "📸 Integration test screenshots: captured via binding (viewable in test output)"
log "📁 Output directory: $SCREENSHOT_DIR"
log "📋 Test log: $LOG_FILE"

if [[ $INTEGRATION_EXIT -eq 0 ]]; then
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}  All checks passed — ready to deploy!  ${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}  Tests completed with issues — review log.   ${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi

echo ""
echo "To open screenshots: open $SCREENSHOT_DIR"
exit $INTEGRATION_EXIT
