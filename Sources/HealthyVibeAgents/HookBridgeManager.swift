import Foundation

public final class HookBridgeManager {
    public let applicationSupportDirectory: URL
    public let eventsDirectory: URL
    public let hooksDirectory: URL
    public let homeDirectory: URL

    private let fileManager: FileManager
    private let jsonDecoder: JSONDecoder

    public init(
        applicationSupportDirectory: URL,
        eventsDirectory: URL,
        hooksDirectory: URL,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) {
        self.applicationSupportDirectory = applicationSupportDirectory
        self.eventsDirectory = eventsDirectory
        self.hooksDirectory = hooksDirectory
        self.homeDirectory = homeDirectory
        self.fileManager = fileManager

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder

    }

    public var bridgeScriptURL: URL {
        hooksDirectory.appendingPathComponent("agent-event.sh", isDirectory: false)
    }

    public func installBridgeScript() throws {
        try fileManager.createDirectory(at: eventsDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: hooksDirectory, withIntermediateDirectories: true)

        let script = bridgeScript()
        try script.write(to: bridgeScriptURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: bridgeScriptURL.path)
    }

    public func connect(_ agent: AgentKind) throws {
        try installBridgeScript()
        let configURL = configURL(for: agent)
        try fileManager.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try backupIfNeeded(configURL)

        var object = try readJSONObject(from: configURL)
        object = addHook(to: object, agent: agent)
        try writeJSONObject(object, to: configURL)
    }

    public func disconnect(_ agent: AgentKind) throws {
        let configURL = configURL(for: agent)
        guard fileManager.fileExists(atPath: configURL.path) else {
            return
        }

        try backupIfNeeded(configURL)
        var object = try readJSONObject(from: configURL)
        object = removeHook(from: object, agent: agent)
        try writeJSONObject(object, to: configURL)
    }

    public func status(for agent: AgentKind) -> AgentConnectionStatus {
        let configURL = configURL(for: agent)
        guard fileManager.fileExists(atPath: configURL.path) else {
            return .configMissing
        }

        do {
            let object = try readJSONObject(from: configURL)
            return containsHealthyVibeHook(object, agent: agent) ? .connected : .notConnected
        } catch {
            return .invalidConfig
        }
    }

    public func statuses() -> [AgentKind: AgentConnectionStatus] {
        Dictionary(uniqueKeysWithValues: AgentKind.allCases.map { ($0, status(for: $0)) })
    }

    public func sendTestEvent(for agent: AgentKind) throws {
        try installBridgeScript()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [bridgeScriptURL.path, agent.rawValue]
        process.standardInput = Pipe()
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        if let input = process.standardInput as? Pipe {
            input.fileHandleForWriting.write(Data("{\"prompt\":\"healthyvibe test\"}".utf8))
            input.fileHandleForWriting.closeFile()
        }
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw HookBridgeError.testEventFailed(agent.displayName)
        }
    }

    public func readPendingEvents() throws -> [HookEvent] {
        guard fileManager.fileExists(atPath: eventsDirectory.path) else {
            return []
        }

        let files = try fileManager.contentsOfDirectory(
            at: eventsDirectory,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var events: [HookEvent] = []
        for file in files {
            do {
                let data = try Data(contentsOf: file)
                let envelope = try jsonDecoder.decode(HookEventEnvelope.self, from: data)
                events.append(HookEvent(
                    id: file.deletingPathExtension().lastPathComponent,
                    source: envelope.source,
                    event: envelope.event,
                    receivedAt: envelope.receivedAt
                ))
                try fileManager.removeItem(at: file)
            } catch {
                let failedURL = file.deletingPathExtension().appendingPathExtension("failed")
                try? fileManager.moveItem(at: file, to: failedURL)
            }
        }

        return events
    }
}

public enum HookBridgeError: Error, LocalizedError, Equatable {
    case invalidJSON(URL)
    case testEventFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidJSON(let url):
            "Invalid JSON config: \(url.path)"
        case .testEventFailed(let agentName):
            "Failed to send \(agentName) test event."
        }
    }
}

private extension HookBridgeManager {
    func configURL(for agent: AgentKind) -> URL {
        switch agent {
        case .claude:
            homeDirectory.appendingPathComponent(".claude/settings.json", isDirectory: false)
        case .codex:
            homeDirectory.appendingPathComponent(".codex/hooks.json", isDirectory: false)
        }
    }

    func bridgeScript() -> String {
        """
        #!/usr/bin/env bash
        set -euo pipefail

        SOURCE="${1:-unknown}"
        APP_SUPPORT=\(shellQuote(applicationSupportDirectory.path))
        EVENT_DIR="$APP_SUPPORT/events"
        mkdir -p "$EVENT_DIR"

        # Discard hook payload immediately. UserPromptSubmit may contain prompt text.
        if [ ! -t 0 ]; then
          cat >/dev/null || true
        fi

        RECEIVED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        EVENT_ID="$(date -u +"%Y%m%dT%H%M%SZ")-$$-$RANDOM"
        TMP_FILE="$EVENT_DIR/$EVENT_ID.tmp"
        OUT_FILE="$EVENT_DIR/$EVENT_ID.json"

        printf '{"source":"%s","event":"prompt_submitted","receivedAt":"%s"}\\n' "$SOURCE" "$RECEIVED_AT" > "$TMP_FILE"
        mv "$TMP_FILE" "$OUT_FILE"

        open -gj -a "HealthyVibe" >/dev/null 2>&1 || true
        exit 0
        """
    }

    func hookCommand(for agent: AgentKind) -> String {
        "\(shellQuote(bridgeScriptURL.path)) \(agent.rawValue)"
    }

    func hookHandler(for agent: AgentKind) -> [String: Any] {
        [
            "type": "command",
            "command": hookCommand(for: agent),
            "timeout": 5,
            "statusMessage": "HealthyVibe"
        ]
    }

    func addHook(to object: [String: Any], agent: AgentKind) -> [String: Any] {
        if containsHealthyVibeHook(object, agent: agent) {
            return object
        }

        var updated = object
        var hooks = updated["hooks"] as? [String: Any] ?? [:]
        var groups = hooks["UserPromptSubmit"] as? [[String: Any]] ?? []
        groups.append(["hooks": [hookHandler(for: agent)]])
        hooks["UserPromptSubmit"] = groups
        updated["hooks"] = hooks
        return updated
    }

    func removeHook(from object: [String: Any], agent: AgentKind) -> [String: Any] {
        var updated = object
        var hooks = updated["hooks"] as? [String: Any] ?? [:]
        var groups = hooks["UserPromptSubmit"] as? [[String: Any]] ?? []

        groups = groups.compactMap { group in
            var updatedGroup = group
            let handlers = updatedGroup["hooks"] as? [[String: Any]] ?? []
            let remainingHandlers = handlers.filter { !isHealthyVibeHandler($0, agent: agent) }

            if remainingHandlers.isEmpty && group.keys.allSatisfy({ $0 == "hooks" || $0 == "matcher" }) {
                return nil
            }

            updatedGroup["hooks"] = remainingHandlers
            return updatedGroup
        }

        if groups.isEmpty {
            hooks.removeValue(forKey: "UserPromptSubmit")
        } else {
            hooks["UserPromptSubmit"] = groups
        }

        if hooks.isEmpty {
            updated.removeValue(forKey: "hooks")
        } else {
            updated["hooks"] = hooks
        }

        return updated
    }

    func containsHealthyVibeHook(_ object: [String: Any], agent: AgentKind) -> Bool {
        guard
            let hooks = object["hooks"] as? [String: Any],
            let groups = hooks["UserPromptSubmit"] as? [[String: Any]]
        else {
            return false
        }

        return groups.contains { group in
            let handlers = group["hooks"] as? [[String: Any]] ?? []
            return handlers.contains { isHealthyVibeHandler($0, agent: agent) }
        }
    }

    func isHealthyVibeHandler(_ handler: [String: Any], agent: AgentKind) -> Bool {
        guard let command = handler["command"] as? String else {
            return false
        }

        return command.contains(bridgeScriptURL.path) && command.contains(agent.rawValue)
    }

    func readJSONObject(from url: URL) throws -> [String: Any] {
        guard fileManager.fileExists(atPath: url.path) else {
            return [:]
        }

        let data = try Data(contentsOf: url)
        guard !data.isEmpty else {
            return [:]
        }

        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else {
            throw HookBridgeError.invalidJSON(url)
        }

        return dictionary
    }

    func writeJSONObject(_ object: [String: Any], to url: URL) throws {
        let data = try JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        try data.write(to: url, options: .atomic)
    }

    func backupIfNeeded(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }

        let timestamp = ISO8601DateFormatter()
            .string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let backupURL = url.deletingLastPathComponent()
            .appendingPathComponent("\(url.lastPathComponent).healthyvibe-backup-\(timestamp)-\(UUID().uuidString)")
        try fileManager.copyItem(at: url, to: backupURL)
    }

    func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\"'\"'"))'"
    }
}
