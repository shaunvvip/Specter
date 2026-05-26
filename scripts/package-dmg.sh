#!/bin/bash
# Build an unsigned .dmg of Specter for local testing.
# For a notarized release DMG, this needs to be paired with notarize.sh (TODO).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

./scripts/build-preview-bundle.sh
xcodegen generate
xcodebuild -project Specter.xcodeproj -scheme Specter -configuration Release \
    -derivedDataPath ./build clean build

APP="./build/Build/Products/Release/Specter.app"
if [ ! -d "$APP" ]; then
  echo "✗ Build did not produce $APP" >&2
  exit 1
fi

DMG_DIR="$(mktemp -d)"
cp -R "$APP" "$DMG_DIR/Specter.app"
ln -s /Applications "$DMG_DIR/Applications"

VERSION="$(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist")"
OUT="./dist/Specter-$VERSION.dmg"
mkdir -p ./dist

hdiutil create -volname "Specter $VERSION" -srcfolder "$DMG_DIR" \
    -ov -format UDZO "$OUT"
rm -rf "$DMG_DIR"
echo "✓ Wrote $OUT"
echo ""
echo "Next steps to ship a public release:"
echo "  1. codesign --deep --force --options runtime --sign 'Developer ID Application: …' $APP"
echo "  2. xcrun notarytool submit $OUT --apple-id <you> --team-id <TEAM> --password <app-specific-pwd>"
echo "  3. xcrun stapler staple $OUT"
