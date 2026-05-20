#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-debug}"
APP_DIR=".build/HealthyVibe.app"

if [[ "$CONFIGURATION" == "release" ]]; then
  swift build -c release
  BUILD_DIR=".build/release"
else
  swift build
  BUILD_DIR=".build/debug"
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/HealthyVibe" "$APP_DIR/Contents/MacOS/HealthyVibe"
cp "Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
if [[ -f "Resources/HealthyVibe.icns" ]]; then
  cp "Resources/HealthyVibe.icns" "$APP_DIR/Contents/Resources/HealthyVibe.icns"
fi
chmod +x "$APP_DIR/Contents/MacOS/HealthyVibe"

echo "$APP_DIR"
