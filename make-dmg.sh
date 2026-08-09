#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="ClockOverlay"
VERSION="1.0"
VOL_NAME="Clock Overlay"
DMG_FINAL="dist/${APP_NAME}-${VERSION}.dmg"
DMG_RW="/tmp/${APP_NAME}-${VERSION}.rw.dmg"
STAGING="/tmp/${APP_NAME}-dmg-staging"
MOUNT_DIR="/Volumes/${VOL_NAME}"

echo "==> Building app bundle..."
./build.sh

echo "==> Staging files..."
rm -rf "$STAGING" "$DMG_RW" "$DMG_FINAL"
mkdir -p "$STAGING/.background" "$(dirname "$DMG_FINAL")"

cp -R "build/${APP_NAME}.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "==> Rendering installer background..."
swift "Scripts/make_background.swift" "$STAGING/.background/background.png"

echo "==> Creating read-write DMG..."
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGING" -ov -format UDRW "$DMG_RW" >/dev/null

echo "==> Applying window layout..."
MOUNTED=$(hdiutil attach "$DMG_RW" -nobrowse -readwrite | awk -F '\t' 'END {print $NF}')
if [ -d "$MOUNTED" ]; then
    osascript <<EOF || true
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 760, 528}
        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 96
        set background picture of theViewOptions to file ".background:background.png" of container window
        set position of item "$APP_NAME.app" of container window to {150, 170}
        set position of item "Applications" of container window to {500, 170}
        close
        update
    end tell
end tell
EOF
    hdiutil detach "$MOUNTED" >/dev/null
else
    echo "!! Warning: could not mount for layout (continuing)"
fi

echo "==> Compressing final DMG..."
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL" >/dev/null
rm -rf "$STAGING" "$DMG_RW"

echo "==> Done: $DMG_FINAL"
hdiutil imageinfo "$DMG_FINAL" | grep -E "format|Checksum" | head -3
