import SwiftUI
import HealthyVibeAgents
import HealthyVibeTeam

struct SettingsPageView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var isConfirmingClear = false
    @State private var teamCodeInput = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: HVSpacing.large) {
                settingsSection("Agents") {
                    agentRow(.claude)
                    Divider()
                        .overlay(HVColor.border)
                        .padding(.vertical, HVSpacing.xsmall)
                    agentRow(.codex)
                }

                settingsSection("通知") {
                    settingsRow(title: "系统通知", value: appModel.notificationPermissionState.displayText)

                    if appModel.notificationPermissionState == .notDetermined {
                        Button("开启通知") {
                            appModel.requestNotificationPermission()
                        }
                        .buttonStyle(HVSecondaryButtonStyle())
                        .padding(.top, HVSpacing.small)
                    }

                    if appModel.notificationPermissionState == .denied {
                        Text("通知关闭时仍会记录事件和更新任务，但不会弹出系统通知。")
                            .font(.system(size: 11))
                            .foregroundStyle(HVColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Button("打开系统设置") {
                            appModel.openNotificationSettings()
                        }
                        .buttonStyle(HVSecondaryButtonStyle())
                        .padding(.top, HVSpacing.small)
                    }

                    Button("模拟 prompt_submitted") {
                        appModel.simulatePromptSubmitted()
                    }
                    .buttonStyle(HVSecondaryButtonStyle())
                    .padding(.top, HVSpacing.small)

                    if let message = appModel.lastReminderMessage {
                        Text(message)
                            .font(.system(size: 11))
                            .foregroundStyle(HVColor.mutedText)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, HVSpacing.xsmall)
                    }
                }

                settingsSection("小队") {
                    teamSection
                }

                settingsSection("偏好") {
                    settingsRow(title: "每日目标", value: "\(appModel.todayTaskState.targetMinutes) 分钟")
                    settingsRow(title: "冷却时间", value: "30 分钟")
                }

                settingsSection("隐私") {
                    Text("延寿分钟是 HealthyVibe 内的娱乐积分，用于鼓励短暂休息和轻量活动，不构成医学建议。")
                        .font(.system(size: 11))
                        .foregroundStyle(HVColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("本地 hook 只记录最小事件，不保存 prompt、代码路径、diff、命令内容或原始 payload；Relay 只接收小队 hash 和当天延寿结果。")
                        .font(.system(size: 11))
                        .foregroundStyle(HVColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, HVSpacing.small)
                }

                settingsSection("本地数据") {
                    Text(appModel.paths.applicationSupportDirectory.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(HVColor.mutedText)
                        .lineLimit(2)
                        .textSelection(.enabled)

                    Button(isConfirmingClear ? "确认清除本地数据" : "清除本地数据") {
                        if isConfirmingClear {
                            appModel.clearLocalData()
                            isConfirmingClear = false
                        } else {
                            isConfirmingClear = true
                        }
                    }
                    .buttonStyle(HVSecondaryButtonStyle())
                    .padding(.top, HVSpacing.small)

                    if isConfirmingClear {
                        Text("会删除任务历史、日历统计、小队缓存和本地设置。")
                            .font(.system(size: 11))
                            .foregroundStyle(HVColor.warmAccent)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(HVSpacing.large)
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: HVSpacing.small) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HVColor.mutedText)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                content()
            }
            .padding(HVSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HVColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: HVRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: HVRadius.medium, style: .continuous)
                    .stroke(HVColor.border, lineWidth: 1)
            )
        }
    }

    private func settingsRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(HVColor.primaryText)
            Spacer(minLength: HVSpacing.medium)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HVColor.secondaryText)
                .lineLimit(1)
        }
        .frame(height: 24)
    }

    @ViewBuilder
    private var teamSection: some View {
        if let profile = appModel.teamProfile {
            settingsRow(title: "小队码", value: profile.teamCode)

            if let teamRankText = appModel.teamRankText {
                Divider()
                    .overlay(HVColor.border)
                    .padding(.vertical, HVSpacing.xsmall)
                settingsRow(title: "今日排名", value: teamRankText.replacingOccurrences(of: "小队排名 ", with: ""))
            }

            if let ranking = appModel.teamRanking {
                Divider()
                    .overlay(HVColor.border)
                    .padding(.vertical, HVSpacing.xsmall)

                VStack(alignment: .leading, spacing: HVSpacing.xsmall) {
                    ForEach(ranking.members.prefix(8)) { member in
                        rankingRow(member, isSelf: member.memberIdHash == profile.memberIDHash)
                    }
                }
            }

            HStack(spacing: HVSpacing.small) {
                Button("同步") {
                    appModel.syncTeamSnapshot()
                }
                .buttonStyle(HVSecondaryButtonStyle())

                Button("退出") {
                    appModel.leaveTeam()
                }
                .buttonStyle(HVSecondaryButtonStyle())
            }
            .padding(.top, HVSpacing.small)
        } else {
            settingsRow(title: "小队", value: "未加入")

            TextField("输入小队码", text: $teamCodeInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
                .padding(.top, HVSpacing.xsmall)

            HStack(spacing: HVSpacing.small) {
                Button("创建小队") {
                    appModel.createTeam()
                }
                .buttonStyle(HVSecondaryButtonStyle())

                Button("加入") {
                    appModel.joinTeam(code: teamCodeInput)
                    teamCodeInput = ""
                }
                .buttonStyle(HVSecondaryButtonStyle())
                .disabled(teamCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top, HVSpacing.small)
        }

        if let message = appModel.teamStatusMessage {
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(HVColor.mutedText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, HVSpacing.small)
        }
    }

    private func rankingRow(_ member: TeamRankingMember, isSelf: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: HVSpacing.small) {
            Text("#\(member.rank)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(isSelf ? HVColor.calmAccent : HVColor.secondaryText)
                .frame(width: 28, alignment: .leading)

            Text(displayName(for: member, isSelf: isSelf))
                .font(.system(size: 12, weight: isSelf ? .semibold : .medium))
                .foregroundStyle(HVColor.primaryText)
                .lineLimit(1)

            Spacer(minLength: HVSpacing.small)

            Text("\(member.longevityMinutes) 分钟")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(HVColor.secondaryText)
                .lineLimit(1)
        }
        .frame(height: 22)
    }

    private func displayName(for member: TeamRankingMember, isSelf: Bool) -> String {
        if isSelf {
            return "我"
        }

        if let displayName = member.displayName, !displayName.isEmpty {
            return displayName
        }

        return "队友 \(String(member.memberIdHash.prefix(4)))"
    }

    private func agentRow(_ agent: AgentKind) -> some View {
        VStack(alignment: .leading, spacing: HVSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text(agent.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HVColor.primaryText)
                Spacer(minLength: HVSpacing.medium)
                Text(appModel.status(for: agent).displayText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(agentStatusColor(agent))
                    .lineLimit(1)
            }

            HStack(spacing: HVSpacing.small) {
                Button(appModel.status(for: agent) == .connected ? "断开" : "连接") {
                    if appModel.status(for: agent) == .connected {
                        appModel.disconnectAgent(agent)
                    } else {
                        appModel.connectAgent(agent)
                    }
                }
                .buttonStyle(HVSecondaryButtonStyle())

                Button("测试") {
                    appModel.testAgentHook(agent)
                }
                .buttonStyle(HVSecondaryButtonStyle())
            }

            Text(agent.configDescription)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(HVColor.mutedText)
                .lineLimit(1)
        }
    }

    private func agentStatusColor(_ agent: AgentKind) -> Color {
        switch appModel.status(for: agent) {
        case .connected:
            HVColor.calmAccent
        case .invalidConfig:
            HVColor.warmAccent
        case .notConnected, .configMissing:
            HVColor.secondaryText
        }
    }
}
