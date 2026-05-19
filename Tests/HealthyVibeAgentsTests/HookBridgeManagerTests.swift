import Foundation
import XCTest
@testable import HealthyVibeAgents

final class HookBridgeManagerTests: XCTestCase {
    func testConnectPreservesExistingClaudeHooksAndDisconnectRemovesOnlyHealthyVibeHook() throws {
        let fixture = try makeFixture()
        defer { fixture.cleanup() }

        let claudeConfigURL = fixture.home.appendingPathComponent(".claude/settings.json")
        try FileManager.default.createDirectory(
            at: claudeConfigURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try """
        {
          "hooks": {
            "UserPromptSubmit": [
              {
                "hooks": [
                  { "type": "command", "command": "echo existing" }
                ]
              }
            ]
          }
        }
        """.write(to: claudeConfigURL, atomically: true, encoding: .utf8)

        try fixture.manager.connect(.claude)
        XCTAssertEqual(fixture.manager.status(for: .claude), .connected)

        let connected = try readJSON(claudeConfigURL)
        let groups = try userPromptGroups(connected)
        XCTAssertEqual(groups.count, 2)

        try fixture.manager.disconnect(.claude)
        XCTAssertEqual(fixture.manager.status(for: .claude), .notConnected)

        let disconnected = try readJSON(claudeConfigURL)
        let remainingGroups = try userPromptGroups(disconnected)
        let remainingHandlers = remainingGroups.flatMap { $0["hooks"] as? [[String: Any]] ?? [] }
        XCTAssertEqual(remainingHandlers.count, 1)
        XCTAssertEqual(remainingHandlers[0]["command"] as? String, "echo existing")
    }

    func testConnectCodexCreatesHooksJSONAndBackupOnSecondWrite() throws {
        let fixture = try makeFixture()
        defer { fixture.cleanup() }

        try fixture.manager.connect(.codex)
        XCTAssertEqual(fixture.manager.status(for: .codex), .connected)

        let codexConfigURL = fixture.home.appendingPathComponent(".codex/hooks.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: codexConfigURL.path))

        try fixture.manager.disconnect(.codex)
        let backups = try FileManager.default.contentsOfDirectory(
            at: codexConfigURL.deletingLastPathComponent(),
            includingPropertiesForKeys: nil
        )
        .filter { $0.lastPathComponent.contains("healthyvibe-backup") }
        XCTAssertFalse(backups.isEmpty)
    }

    func testBridgeScriptWritesMinimalEventAndDiscardsPromptPayload() throws {
        let fixture = try makeFixture()
        defer { fixture.cleanup() }

        try fixture.manager.installBridgeScript()
        try fixture.manager.sendTestEvent(for: .codex)

        let eventFiles = try FileManager.default.contentsOfDirectory(
            at: fixture.events,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension == "json" }
        XCTAssertEqual(eventFiles.count, 1)

        let eventData = try Data(contentsOf: eventFiles[0])
        let eventText = String(decoding: eventData, as: UTF8.self)
        XCTAssertFalse(eventText.contains("healthyvibe test"))
        XCTAssertTrue(eventText.contains("\"source\":\"codex\""))
        XCTAssertTrue(eventText.contains("\"event\":\"prompt_submitted\""))

        let events = try fixture.manager.readPendingEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].source, "codex")
        XCTAssertEqual(events[0].event, "prompt_submitted")
    }

    func testInvalidConfigReportsInvalidStatusWithoutOverwriting() throws {
        let fixture = try makeFixture()
        defer { fixture.cleanup() }

        let configURL = fixture.home.appendingPathComponent(".claude/settings.json")
        try FileManager.default.createDirectory(
            at: configURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try "{ invalid".write(to: configURL, atomically: true, encoding: .utf8)

        XCTAssertEqual(fixture.manager.status(for: .claude), .invalidConfig)
        XCTAssertThrowsError(try fixture.manager.connect(.claude))
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), "{ invalid")
    }
}

private extension HookBridgeManagerTests {
    struct Fixture {
        let root: URL
        let home: URL
        let appSupport: URL
        let events: URL
        let hooks: URL
        let manager: HookBridgeManager
        let cleanup: () -> Void
    }

    func makeFixture() throws -> Fixture {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("HealthyVibeAgents-\(UUID().uuidString)", isDirectory: true)
        let home = root.appendingPathComponent("home", isDirectory: true)
        let appSupport = root.appendingPathComponent("Application Support/HealthyVibe", isDirectory: true)
        let events = appSupport.appendingPathComponent("events", isDirectory: true)
        let hooks = appSupport.appendingPathComponent("hooks", isDirectory: true)

        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: events, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: hooks, withIntermediateDirectories: true)

        let manager = HookBridgeManager(
            applicationSupportDirectory: appSupport,
            eventsDirectory: events,
            hooksDirectory: hooks,
            homeDirectory: home
        )

        return Fixture(
            root: root,
            home: home,
            appSupport: appSupport,
            events: events,
            hooks: hooks,
            manager: manager,
            cleanup: { try? FileManager.default.removeItem(at: root) }
        )
    }

    func readJSON(_ url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func userPromptGroups(_ object: [String: Any]) throws -> [[String: Any]] {
        let hooks = try XCTUnwrap(object["hooks"] as? [String: Any])
        return try XCTUnwrap(hooks["UserPromptSubmit"] as? [[String: Any]])
    }
}
