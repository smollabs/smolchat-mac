#!/usr/bin/env bash
# Package dist/SmolChat.app into dist/SmolChat-<version>.dmg (drag-to-Applications layout).
# Run scripts/build_macos.sh first. Uses only built-in macOS tools (hdiutil).
set -euo pipefail
cd "$(dirname "$0")/.."

APP=dist/SmolChat.app
[ -d "$APP" ] || { echo "Missing $APP - run scripts/build_macos.sh first" >&2; exit 1; }

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist" 2>/dev/null || echo "0.0.0")
DMG=dist/SmolChat-$VERSION.dmg

# Stage the app next to an Applications shortcut so users can drag it across.
STAGE=$(mktemp -d)/SmolChat
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create -volname "SmolChat" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$(dirname "$STAGE")"

echo "Built $DMG"
echo "For distribution: codesign -s 'Developer ID Application: …' $DMG, then notarize and staple it."
