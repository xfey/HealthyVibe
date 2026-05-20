import AppKit
import SwiftUI
import HealthyVibeTeam

struct TeamPageView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var teamCodeInput = ""
    @State private var displayNameInput = ""
    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: HVSpacing.small) {
                if let profile = appModel.teamProfile {
                    joinedContent(profile)
                } else {
                    emptyContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 2)
        .onAppear {
            displayNameInput = appModel.teamProfile?.displayName ?? ""
            if appModel.teamProfile != nil {
                appModel.syncTeamSnapshot()
            }
        }
        .onChange(of: appModel.teamProfile?.displayName) { newValue in
            displayNameInput = newValue ?? ""
        }
        .onReceive(refreshTimer) { _ in
            if appModel.teamProfile != nil {
                appModel.refreshTeamRanking()
            }
        }
    }

    private func joinedContent(_ profile: TeamProfile) -> some View {
        VStack(alignment: .leading, spacing: HVSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text("排名")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HVColor.primaryText)
                    .lineLimit(1)

                Spacer(minLength: HVSpacing.small)

                if let rank = appModel.teamRankText {
                    Text(rank.replacingOccurrences(of: "小队排名 ", with: "#"))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(HVColor.calmAccent)
                        .lineLimit(1)
                }
            }

            if let ranking = appModel.teamRanking, !ranking.members.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(ranking.members) { member in
                        rankingRow(member, isSelf: member.memberIdHash == profile.memberIDHash)
                    }
                }
            } else {
                Text("今天还没有队友上榜")
                    .font(.system(size: 11))
                    .foregroundStyle(HVColor.secondaryText)
            }

            HStack(spacing: 5) {
                Text("邀请码 \(profile.teamCode)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(HVColor.mutedText)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Button("复制") {
                    copyTeamCode(profile.teamCode)
                }
                .buttonStyle(HVCompactButtonStyle())
                .frame(width: 34)
            }

            if let message = appModel.teamStatusMessage {
                Text(message)
                    .font(.system(size: 10))
                    .foregroundStyle(HVColor.mutedText)
                    .lineLimit(1)
            }

            bottomControl
        }
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: HVSpacing.small) {
            Text("还没有加入小队")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(HVColor.primaryText)

            Text("输入小队码加入小队。")
                .font(.system(size: 11))
                .foregroundStyle(HVColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let message = appModel.teamStatusMessage {
                Text(message)
                    .font(.system(size: 10))
                    .foregroundStyle(HVColor.mutedText)
                    .lineLimit(2)
            }

            bottomControl
        }
    }

    @ViewBuilder
    private var bottomControl: some View {
        if appModel.teamProfile == nil {
            HStack(spacing: 6) {
                compactTextField("6位码", text: $teamCodeInput, monospaced: true)

                Button("加入") {
                    appModel.joinTeam(code: teamCodeInput)
                    teamCodeInput = ""
                }
                .buttonStyle(HVCompactButtonStyle(isPrimary: true))
                .frame(width: 38)
                .disabled(!TeamIdentity.isValidTeamCode(teamCodeInput))

                Button("创建") {
                    appModel.createTeam()
                    teamCodeInput = ""
                }
                .buttonStyle(HVCompactButtonStyle())
                .frame(width: 38)
            }
            .onChange(of: teamCodeInput) { newValue in
                let normalized = TeamIdentity.normalizeTeamCode(newValue)
                if normalized != newValue {
                    teamCodeInput = normalized
                }
            }
        } else {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    compactTextField("我的名字", text: $displayNameInput)

                    Button("保存") {
                        appModel.updateTeamDisplayName(displayNameInput)
                    }
                    .buttonStyle(HVCompactButtonStyle(isPrimary: hasDisplayNameChange))
                    .frame(width: 38)
                    .disabled(!hasDisplayNameChange)
                }

                Button("退出小队") {
                    appModel.leaveTeam()
                    displayNameInput = ""
                }
                .buttonStyle(HVCompactButtonStyle())
            }
        }
    }

    private func rankingRow(_ member: TeamRankingMember, isSelf: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text("#\(member.rank)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(isSelf ? HVColor.calmAccent : HVColor.secondaryText)
                .frame(width: 24, alignment: .leading)

            Text(isSelf ? "我" : displayName(for: member))
                .font(.system(size: 11, weight: isSelf ? .semibold : .medium))
                .foregroundStyle(HVColor.primaryText)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text("\(member.longevityMinutes)m")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(HVColor.secondaryText)
                .lineLimit(1)
        }
        .frame(height: 16)
    }

    private func displayName(for member: TeamRankingMember) -> String {
        if let displayName = member.displayName, !displayName.isEmpty {
            return displayName
        }

        return "队友 \(String(member.memberIdHash.prefix(4)))"
    }

    private func copyTeamCode(_ code: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
    }

    private var hasDisplayNameChange: Bool {
        TeamIdentity.normalizeDisplayName(displayNameInput) != appModel.teamProfile?.displayName
    }

    private func compactTextField(
        _ placeholder: String,
        text: Binding<String>,
        monospaced: Bool = false
    ) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(monospaced
                  ? .system(size: 11, weight: .medium, design: .monospaced)
                  : .system(size: 11, weight: .medium))
            .foregroundStyle(HVColor.primaryText)
            .padding(.horizontal, 6)
            .frame(height: 21)
            .background(HVColor.border.opacity(0.25))
            .overlay(Rectangle().stroke(HVColor.border, lineWidth: 1))
    }
}
