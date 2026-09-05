#!/usr/bin/env bash
# Install & launch Qiyama without Xcode debugger (skips shared-cache symbol copy).
#
# Requires a physical device. Set IDs in scripts/run-native.local.sh (gitignored)
# or export QIYAMA_DESTINATION / QIYAMA_DEVICE_ID / DEVELOPMENT_TEAM.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -f "$ROOT/scripts/run-native.local.sh" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT/scripts/run-native.local.sh"
fi

: "${QIYAMA_DESTINATION:?Set QIYAMA_DESTINATION (e.g. platform=iOS,id=…)}"
: "${QIYAMA_DEVICE_ID:?Set QIYAMA_DEVICE_ID (CoreDevice UUID from xcrun devicectl)}"
: "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM (Apple Development Team ID)}"

xcodegen generate >/dev/null
xcodebuild -scheme Qiyama -destination "$QIYAMA_DESTINATION" -configuration Debug \
  -derivedDataPath ./DerivedData \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  build
APP="./DerivedData/Build/Products/Debug-iphoneos/Qiyama.app"
xcrun devicectl device install app --device "$QIYAMA_DEVICE_ID" "$APP"
xcrun devicectl device process launch --device "$QIYAMA_DEVICE_ID" app.qiyama.train
echo "Launched Qiyama (no debugger / no symbol copy)."
