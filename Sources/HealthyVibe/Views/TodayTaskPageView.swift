import SwiftUI

struct TodayTaskPageView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: HVSpacing.large) {
            if let message = appModel.lastErrorMessage {
                statusBanner(message)
            }

            HVCard {
                VStack(alignment: .leading, spacing: HVSpacing.medium) {
                    Text("等待下一次 agent 开工")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(HVColor.primaryText)
                        .lineLimit(2)

                    Text("Phase 1 会接入每日固定任务池。现在先保留核心菜单栏体验。")
                        .font(.system(size: 13))
                        .foregroundStyle(HVColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("今日 0 / 30 分钟")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HVColor.secondaryText)

                    HVProgressBar(value: 0)

                    HStack(spacing: HVSpacing.small) {
                        Button("完成") {}
                            .buttonStyle(HVPrimaryButtonStyle())
                            .disabled(true)
                        Button("换一个") {}
                            .buttonStyle(HVSecondaryButtonStyle())
                            .disabled(true)
                    }
                    .opacity(0.55)
                }
            }

            Text("本阶段只搭好 UI 骨架、目录和状态边界，不引入任务逻辑。")
                .font(.system(size: 12))
                .foregroundStyle(HVColor.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(HVSpacing.large)
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
