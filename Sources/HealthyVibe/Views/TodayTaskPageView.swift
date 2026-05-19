import SwiftUI
import HealthyVibeCore

struct TodayTaskPageView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: HVSpacing.medium) {
            if let message = appModel.lastErrorMessage {
                statusBanner(message)
            }

            card

            if let teamRankText = appModel.teamRankText {
                teamRankBadge(teamRankText)
            }

            Spacer(minLength: 0)
        }
        .padding(HVSpacing.large)
        .onAppear {
            appModel.refreshForCurrentDay()
        }
    }

    @ViewBuilder
    private var card: some View {
        switch appModel.todayTaskState.cardStatus {
        case .pending(let item):
            pendingTaskCard(item)
        case .completed(let summary):
            completedTaskCard(summary)
        case .allCompleted:
            allCompletedCard
        case .waiting:
            waitingCard
        }
    }

    private func pendingTaskCard(_ item: DailyTaskItem) -> some View {
        HVCard {
            VStack(alignment: .leading, spacing: HVSpacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.template.title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(HVColor.primaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.88)

                    Spacer(minLength: HVSpacing.small)

                    Text("\(item.completedCount)/\(item.template.maxDailyCount)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HVColor.calmAccent)
                        .padding(.horizontal, HVSpacing.small)
                        .padding(.vertical, 3)
                        .background(HVColor.successFill)
                        .clipShape(Capsule())
                }

                Text(item.template.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(HVColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LongevityCopy.rewardLine(for: item))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HVColor.warmAccent)
                    .fixedSize(horizontal: false, vertical: true)

                progressBlock

                HStack(spacing: HVSpacing.small) {
                    Button("完成") {
                        appModel.completeCurrentTask()
                    }
                    .buttonStyle(HVPrimaryButtonStyle())

                    Button("换一个") {
                        appModel.switchCurrentTask()
                    }
                    .buttonStyle(HVSecondaryButtonStyle())
                    .disabled(!appModel.canSwitchTask)
                }
            }
        }
    }

    private func completedTaskCard(_ summary: TaskCompletionSummary) -> some View {
        HVCard {
            VStack(alignment: .leading, spacing: HVSpacing.medium) {
                Text("本轮已续命")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(HVColor.primaryText)

                Text("+\(summary.rewardMinutes) 分钟")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(HVColor.calmAccent)

                Text(LongevityCopy.totalLine(forTotalMinutes: summary.totalLongevityMinutes))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HVColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                progressBlock

                HStack(spacing: HVSpacing.small) {
                    Text("下一次 agent 开工后再提醒")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HVColor.mutedText)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var waitingCard: some View {
        HVCard {
            VStack(alignment: .leading, spacing: HVSpacing.medium) {
                Text("等待下一次 agent 开工")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(HVColor.primaryText)
                    .lineLimit(2)

                Text(waitingMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(HVColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                progressBlock

                if !appModel.hasConnectedAgent {
                    Button("去设置连接 Agent") {
                        appModel.selectedPage = .settings
                    }
                    .buttonStyle(HVPrimaryButtonStyle())
                }
            }
        }
    }

    private var allCompletedCard: some View {
        HVCard {
            VStack(alignment: .leading, spacing: HVSpacing.medium) {
                Text("今日任务池已清空")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(HVColor.primaryText)

                Text("所有固定任务次数都已完成，今天不用继续刷任务。")
                    .font(.system(size: 13))
                    .foregroundStyle(HVColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LongevityCopy.totalLine(forTotalMinutes: appModel.todayTaskState.totalLongevityMinutes))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HVColor.calmAccent)
                    .fixedSize(horizontal: false, vertical: true)

                progressBlock
            }
        }
    }

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: HVSpacing.small) {
            HStack(spacing: HVSpacing.small) {
                Text(appModel.todayProgressText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HVColor.secondaryText)

                if appModel.todayTaskState.progressFraction >= 1 {
                    Text("目标达成")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HVColor.calmAccent)
                        .padding(.horizontal, HVSpacing.small)
                        .padding(.vertical, 2)
                        .background(HVColor.successFill)
                        .clipShape(Capsule())
                }

                Spacer(minLength: 0)
            }

            HVProgressBar(value: appModel.todayTaskState.progressFraction)
        }
    }

    private var waitingMessage: String {
        if appModel.hasConnectedAgent {
            return "超过 30 分钟后，新的 prompt 会触发一次提醒；连续 1 小时活跃但没有 hook，也会兜底发一张。"
        }

        return "先在设置页连接 Claude Code 或 Codex。连接后，新的 prompt 会在冷却结束时触发提醒。"
    }

    private func teamRankBadge(_ text: String) -> some View {
        HStack(spacing: HVSpacing.small) {
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HVColor.calmAccent)
                .lineLimit(1)

            Spacer(minLength: 0)

            if let message = appModel.teamStatusMessage {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(HVColor.mutedText)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, HVSpacing.medium)
        .padding(.vertical, HVSpacing.small)
        .background(HVColor.successFill)
        .clipShape(RoundedRectangle(cornerRadius: HVRadius.small, style: .continuous))
    }

    private func statusBanner(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(HVColor.primaryText)
            .padding(.horizontal, HVSpacing.medium)
            .padding(.vertical, HVSpacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HVColor.warningFill)
            .clipShape(RoundedRectangle(cornerRadius: HVRadius.small, style: .continuous))
    }
}
