import AppKit
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

            if let message = appModel.agentStatusMessage ?? appModel.agentHintText {
                Text(message)
                    .font(.system(size: 10))
                    .foregroundStyle(HVColor.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button("退出应用") {
                NSApp.terminate(nil)
            }
            .buttonStyle(HVCompactButtonStyle())
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
