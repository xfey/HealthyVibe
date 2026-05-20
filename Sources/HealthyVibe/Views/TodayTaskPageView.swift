import SwiftUI
import HealthyVibeCore

struct TodayTaskPageView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: HVSpacing.small) {
            if let message = appModel.lastErrorMessage {
                statusBanner(message)
            }

            card

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 2)
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
        taskPanel {
            VStack(alignment: .leading, spacing: HVSpacing.small) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.template.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(HVColor.primaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.88)

                    Spacer(minLength: HVSpacing.small)

                    Text("\(item.completedCount)/\(item.template.maxDailyCount)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(HVColor.calmAccent)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(HVColor.successFill)
                }

                Text(item.template.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(HVColor.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LongevityCopy.rewardLine(for: item))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(HVColor.warmAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 12)

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
        taskPanel {
            VStack(alignment: .leading, spacing: HVSpacing.small) {
                Text("本轮已续命")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HVColor.primaryText)

                Text("+\(summary.rewardMinutes) 分钟")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(HVColor.calmAccent)

                Text(LongevityCopy.totalLine(forTotalMinutes: summary.totalLongevityMinutes))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HVColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

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
        taskPanel {
            VStack(alignment: .leading, spacing: HVSpacing.small) {
                Text("等待下一次 agent 开工")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HVColor.primaryText)
                    .lineLimit(2)

                Text(waitingMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(HVColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

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
        taskPanel {
            VStack(alignment: .leading, spacing: HVSpacing.small) {
                Text("今日任务池已清空")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HVColor.primaryText)

                Text("所有固定任务次数都已完成，今天不用继续刷任务。")
                    .font(.system(size: 11))
                    .foregroundStyle(HVColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LongevityCopy.totalLine(forTotalMinutes: appModel.todayTaskState.totalLongevityMinutes))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HVColor.calmAccent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func taskPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var waitingMessage: String {
        if appModel.hasConnectedAgent {
            return "冷却结束后再提醒。"
        }

        return "先连接 Claude Code 或 Codex。"
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
