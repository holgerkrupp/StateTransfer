#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="StateTransfer"
BUNDLE_ID="de.holgerkrupp.StateTransfer"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/StateTransfer.xcodeproj"
SCHEME="StateTransfer"
CONFIGURATION="Debug"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=macOS" \
  build

BUILD_SETTINGS="$(
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "platform=macOS" \
    -showBuildSettings
)"
TARGET_BUILD_DIR="$(awk -F ' = ' '/TARGET_BUILD_DIR = / { print $2; exit }' <<<"$BUILD_SETTINGS")"
WRAPPER_NAME="$(awk -F ' = ' '/WRAPPER_NAME = / { print $2; exit }' <<<"$BUILD_SETTINGS")"
APP_BUNDLE="$TARGET_BUILD_DIR/$WRAPPER_NAME"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
