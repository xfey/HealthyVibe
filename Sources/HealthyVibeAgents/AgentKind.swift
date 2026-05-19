import Foundation

public enum AgentKind: String, CaseIterable, Codable, Identifiable {
    case claude
    case codex

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .claude:
            "Claude Code"
        case .codex:
            "Codex"
        }
    }

    public var configDescription: String {
        switch self {
        case .claude:
            "~/.claude/settings.json"
        case .codex:
            "~/.codex/hooks.json"
        }
    }
}

public enum AgentConnectionStatus: String, Codable {
    case connected
    case notConnected
    case configMissing
    case invalidConfig

    public var displayText: String {
        switch self {
        case .connected:
            "已连接"
        case .notConnected:
            "未连接"
        case .configMissing:
            "未连接"
        case .invalidConfig:
            "配置异常"
        }
    }
}
