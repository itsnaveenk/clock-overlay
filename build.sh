#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="ClockOverlay"
APP_DIR="build/$APP_NAME.app"

echo "==> Building (release)..."
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/$APP_NAME"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "Support/Info.plist" "$APP_DIR/Contents/Info.plist"

echo "==> Generating app icon..."
swift "Scripts/make_icon.swift" "$APP_DIR/Contents/Resources/AppIcon.icns"

codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

echo "==> Done: $APP_DIR"
echo "    Run:        open $APP_DIR"
echo "    (Optional)  cp -R $APP_DIR /Applications/   # needed for 'Launch at Login'"
