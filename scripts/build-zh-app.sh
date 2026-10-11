#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
DERIVED_DATA="$PROJECT_ROOT/.derivedData/Chinese"
OUTPUT="$PROJECT_ROOT/build"
APP="$OUTPUT/EnviousWispr.app"

if [[ "${1:-}" != "--package-only" ]]; then
  tuist generate --no-open --cache-profile none
  xcodebuild build -workspace EnviousWispr.xcworkspace \
    -scheme EnviousWispr-Release -configuration Release \
    -destination 'platform=macOS,arch=arm64' -derivedDataPath "$DERIVED_DATA" \
    ARCHS=arm64 VALID_ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SU_FEED_URL=
fi
test -d "$DERIVED_DATA/Build/Products/Release/EnviousWispr.app"

mkdir -p "$OUTPUT"
if [[ -e "$APP" ]]; then
  mv "$APP" "$OUTPUT/EnviousWispr.previous.$(date +%Y%m%d-%H%M%S).app"
fi
ditto "$DERIVED_DATA/Build/Products/Release/EnviousWispr.app" "$APP"
plutil -replace SUFeedURL -string '' "$APP/Contents/Info.plist"
plutil -replace EnviousWisprLocalBuild -bool YES "$APP/Contents/Info.plist"
plutil -replace SentryDSN -string '' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :SUEnableAutomaticChecks false' "$APP/Contents/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c 'Add :SUEnableAutomaticChecks bool false' "$APP/Contents/Info.plist"

mkdir -p "$APP/Contents/Resources/Licenses"
cp LICENSE "$APP/Contents/Resources/Licenses/GPL-3.0.txt"
cp THIRD-PARTY-NOTICES.txt "$APP/Contents/Resources/Licenses/THIRD-PARTY-NOTICES.txt"
COMMIT="$(git rev-parse HEAD)"
printf 'Corresponding source: https://github.com/MatriQ/EnviousWispr/tree/%s\nBuild instructions: README.zh-CN.md\n' \
  "$COMMIT" > "$APP/Contents/Resources/Licenses/SOURCE.txt"

SPARKLE_AUTOUPDATE="$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Autoupdate"
if [[ -f "$SPARKLE_AUTOUPDATE" ]]; then
  codesign --force --sign - --timestamp=none "$SPARKLE_AUTOUPDATE"
fi

# Sign nested executable bundles before their containers, including Sparkle's helpers.
while IFS= read -r -d '' bundle; do
  codesign --force --sign - --timestamp=none "$bundle"
done < <(find "$APP/Contents" -depth \( -name '*.app' -o -name '*.xpc' -o -name '*.framework' \) -print0)
codesign --force --sign - --timestamp=none "$APP/Contents/Resources/llama-server"
codesign --force --sign - --timestamp=none \
  --entitlements Sources/EnviousWispr/Resources/EnviousWispr-Dev.entitlements "$APP"
codesign --verify --deep --strict "$APP"

STAGING="$(mktemp -d "$OUTPUT/dmg.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
ditto "$APP" "$STAGING/EnviousWispr.app"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname 'EnviousWispr 简体中文' -srcfolder "$STAGING" \
  -ov -format UDZO "$OUTPUT/EnviousWispr-zh-Hans-arm64.dmg"
printf 'Built: %s\n' "$APP" "$OUTPUT/EnviousWispr-zh-Hans-arm64.dmg"
