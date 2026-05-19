#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ZIP_PATH="${1:?Usage: generate_homebrew_cask.sh <zip> [output] [url]}"
OUTPUT_PATH="${2:-dist/healthyvibe.rb}"
URL_VALUE="${3:-}"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"

if [[ -z "$URL_VALUE" ]]; then
  ZIP_ABS="$(cd "$(dirname "$ZIP_PATH")" && pwd)/$(basename "$ZIP_PATH")"
  URL_VALUE="file://$ZIP_ABS"
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"

cat > "$OUTPUT_PATH" <<RUBY
cask "healthyvibe" do
  version "$VERSION"
  sha256 "$SHA256"

  url "$URL_VALUE"
  name "HealthyVibe"
  desc "Menu bar health breaks for AI coding waits"
  homepage "https://github.com/healthyvibe/HealthyVibe"

  depends_on macos: ">= :ventura"

  app "HealthyVibe.app"

  uninstall quit: "dev.healthyvibe.app"

  uninstall_preflight do
    require "json"
    require "pathname"

    [
      [Pathname("#{Dir.home}/.claude/settings.json"), "claude"],
      [Pathname("#{Dir.home}/.codex/hooks.json"), "codex"],
    ].each do |path, agent|
      next unless path.exist?

      begin
        data = JSON.parse(path.read)
      rescue JSON::ParserError
        next
      end

      hooks = data["hooks"]
      groups = hooks&.[]("UserPromptSubmit")
      next unless groups.is_a?(Array)

      changed = false
      groups.map! do |group|
        next group unless group.is_a?(Hash)

        handlers = group["hooks"]
        next group unless handlers.is_a?(Array)

        remaining = handlers.reject do |handler|
          handler.is_a?(Hash) &&
            handler["command"].to_s.include?("HealthyVibe/hooks/agent-event.sh") &&
            handler["command"].to_s.include?(agent)
        end

        changed ||= remaining.length != handlers.length
        group["hooks"] = remaining

        if remaining.empty? && (group.keys - ["hooks", "matcher"]).empty?
          nil
        else
          group
        end
      end
      groups.compact!

      next unless changed

      if groups.empty?
        hooks.delete("UserPromptSubmit")
      else
        hooks["UserPromptSubmit"] = groups
      end
      data.delete("hooks") if hooks.empty?

      path.write(JSON.pretty_generate(data) + "\\n")
    end
  end

  zap trash: [
    "~/Library/Application Support/HealthyVibe",
    "~/Library/Preferences/dev.healthyvibe.app.plist",
  ]
end
RUBY

echo "$OUTPUT_PATH"
