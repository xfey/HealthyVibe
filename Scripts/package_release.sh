#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
APP_DIR=".build/HealthyVibe.app"
DIST_DIR="dist"
ZIP_PATH="$DIST_DIR/HealthyVibe-$VERSION.zip"
ZIP_ABS="$ROOT_DIR/$ZIP_PATH"

mkdir -p "$DIST_DIR"

./Scripts/build_app_bundle.sh release

if [[ -n "${HEALTHYVIBE_SIGN_IDENTITY:-}" ]]; then
  echo "Signing $APP_DIR with $HEALTHYVIBE_SIGN_IDENTITY"
  codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --sign "$HEALTHYVIBE_SIGN_IDENTITY" \
    "$APP_DIR"
  codesign --verify --deep --strict --verbose=2 "$APP_DIR"
else
  echo "Skipping codesign. Set HEALTHYVIBE_SIGN_IDENTITY for Developer ID signing."
fi

make_zip() {
  rm -f "$ZIP_ABS"
  (
    cd "$(dirname "$APP_DIR")"
    ditto -c -k --norsrc --keepParent "$(basename "$APP_DIR")" "$ZIP_ABS"
  )
}

if [[ -n "${HEALTHYVIBE_NOTARY_PROFILE:-}" ]]; then
  if [[ -z "${HEALTHYVIBE_SIGN_IDENTITY:-}" || "${HEALTHYVIBE_SIGN_IDENTITY:-}" == "-" ]]; then
    echo "Notarization requires a Developer ID signing identity." >&2
    exit 1
  fi

  make_zip
  echo "Submitting $ZIP_PATH for notarization with keychain profile $HEALTHYVIBE_NOTARY_PROFILE"
  xcrun notarytool submit "$ZIP_ABS" \
    --keychain-profile "$HEALTHYVIBE_NOTARY_PROFILE" \
    --wait
  xcrun stapler staple "$APP_DIR"
  xcrun stapler validate "$APP_DIR"
fi

make_zip
shasum -a 256 "$ZIP_PATH" | tee "$ZIP_PATH.sha256"

RELEASE_URL="${HEALTHYVIBE_RELEASE_URL:-file://$ZIP_ABS}"
./Scripts/generate_homebrew_cask.sh "$ZIP_PATH" "$DIST_DIR/healthyvibe.rb" "$RELEASE_URL"

echo "Release archive: $ZIP_PATH"
echo "Generated cask:   $DIST_DIR/healthyvibe.rb"
