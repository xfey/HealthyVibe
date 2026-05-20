import SwiftUI
import HealthyVibeAgents

struct SettingsPageView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("连接 Agent")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HVColor.primaryText)

            HStack(spacing: 6) {
                agentButton(.claude)
                agentButton(.codex)
            }

            Divider()
                .overlay(HVColor.border)

            Text("通知调试")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HVColor.primaryText)

            Text(appModel.notificationPermissionState.displayText)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(HVColor.secondaryText)
                .lineLimit(1)

            HStack(spacing: 6) {
                if appModel.notificationPermissionState == .notDetermined {
                    Button("开启") {
                        appModel.requestNotificationPermission()
                    }
                    .buttonStyle(HVCompactButtonStyle())
                }

                if appModel.notificationPermissionState == .denied {
                    Button("系统") {
                        appModel.openNotificationSettings()
                    }
                    .buttonStyle(HVCompactButtonStyle())
                }

                Button("模拟") {
                    appModel.simulatePromptSubmitted()
                }
                .buttonStyle(HVCompactButtonStyle())
            }

            if let message = appModel.lastReminderMessage {
                Text(message)
                    .font(.system(size: 10))
                    .foregroundStyle(HVColor.mutedText)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func agentButton(_ agent: AgentKind) -> some View {
        if appModel.status(for: agent) == .connected {
            Button(agentButtonTitle(agent)) {
                appModel.disconnectAgent(agent)
            }
            .buttonStyle(HVCompactButtonStyle(isPrimary: true))
        } else {
            Button(agentButtonTitle(agent)) {
                appModel.connectAgent(agent)
            }
            .buttonStyle(HVCompactButtonStyle())
        }
    }

    private func agentButtonTitle(_ agent: AgentKind) -> String {
        let shortName: String
        switch agent {
        case .claude:
            shortName = "Claude"
        case .codex:
            shortName = "Codex"
        }

        return switch appModel.status(for: agent) {
        case .connected:
            "\(shortName) ✓"
        default:
            shortName
        }
    }
}
