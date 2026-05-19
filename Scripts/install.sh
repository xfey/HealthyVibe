#!/usr/bin/env bash
set -euo pipefail

APP_NAME="HealthyVibe.app"
INSTALL_DIR="${HEALTHYVIBE_INSTALL_DIR:-/Applications}"
DEFAULT_URL="https://github.com/healthyvibe/HealthyVibe/releases/latest/download/HealthyVibe.zip"
ZIP_URL="${HEALTHYVIBE_ZIP_URL:-$DEFAULT_URL}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ -n "${HEALTHYVIBE_ZIP_PATH:-}" ]]; then
  cp "$HEALTHYVIBE_ZIP_PATH" "$TMP_DIR/HealthyVibe.zip"
else
  curl -fL "$ZIP_URL" -o "$TMP_DIR/HealthyVibe.zip"
fi

ditto -x -k --norsrc "$TMP_DIR/HealthyVibe.zip" "$TMP_DIR/unpacked"

APP_PATH="$(find "$TMP_DIR/unpacked" -maxdepth 2 -name "$APP_NAME" -type d | head -n 1)"
if [[ -z "$APP_PATH" ]]; then
  echo "HealthyVibe.app was not found in the archive." >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME"
ditto --norsrc "$APP_PATH" "$INSTALL_DIR/$APP_NAME"

if [[ "${HEALTHYVIBE_SKIP_OPEN:-0}" != "1" ]]; then
  open -gj "$INSTALL_DIR/$APP_NAME" || true
fi

echo "Installed $INSTALL_DIR/$APP_NAME"
echo "Use the menu bar icon to connect Claude Code or Codex."
