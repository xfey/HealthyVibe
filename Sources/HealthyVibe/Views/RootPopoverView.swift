import SwiftUI

struct RootPopoverView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(width: LayoutMetrics.popoverWidth, height: PopoverChrome.headerHeight)

            Divider()
                .frame(height: PopoverChrome.dividerHeight)
                .overlay(HVColor.border)

            pageContent
                .frame(
                    width: LayoutMetrics.popoverWidth,
                    height: PopoverChrome.contentHeight,
                    alignment: .top
                )
                .clipped()
                .contentShape(Rectangle())

            footer
                .frame(width: LayoutMetrics.popoverWidth, height: PopoverChrome.footerHeight)
        }
        .frame(width: LayoutMetrics.popoverWidth, height: LayoutMetrics.popoverHeight)
        .background(HVColor.background)
        .simultaneousGesture(pageSwipeGesture)
        .onMoveCommand(perform: moveSelection)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: HVSpacing.small) {
                HVPixelLogoMark(color: HVColor.warmAccent)
                    .frame(width: 18, height: 18)

                Text("Vibe延寿指南")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HVColor.primaryText)
                    .lineLimit(1)

                Spacer(minLength: HVSpacing.small)
            }

            HStack(spacing: 6) {
                HVProgressBar(value: appModel.todayTaskState.progressFraction)

                Text(progressText)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(HVColor.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, HVSpacing.medium)
        .padding(.vertical, 6)
        .background(HVColor.surface)
    }

    private var progressText: String {
        "(\(appModel.todayTaskState.totalLongevityMinutes)/\(appModel.todayTaskState.targetMinutes)分钟)"
    }

    private var footer: some View {
        HStack(spacing: 0) {
            PixelArrowButton(label: "<", isDisabled: isFirstPage) {
                selectPreviousPage()
            }

            Spacer(minLength: 0)

            PixelPageIndicator(selection: $appModel.selectedPage)

            Spacer(minLength: 0)

            PixelArrowButton(label: ">", isDisabled: isLastPage) {
                selectNextPage()
            }
        }
        .padding(.horizontal, HVSpacing.small)
        .background(HVColor.background)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch appModel.selectedPage {
        case .today:
            TodayTaskPageView()
        case .team:
            TeamPageView()
        case .calendar:
            CalendarPageView()
        case .settings:
            SettingsPageView()
        case .about:
            AboutPageView()
        }
    }

    private var pageSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                guard abs(value.translation.width) > 24,
                      abs(value.translation.width) > abs(value.translation.height) * 1.25
                else {
                    return
                }

                if value.translation.width < 0 {
                    selectNextPage()
                } else {
                    selectPreviousPage()
                }
            }
    }

    private func moveSelection(_ direction: MoveCommandDirection) {
        switch direction {
        case .left:
            selectPreviousPage()
        case .right:
            selectNextPage()
        default:
            break
        }
    }

    private func selectPreviousPage() {
        let pages = AppPage.allCases
        guard let index = pages.firstIndex(of: appModel.selectedPage) else {
            return
        }

        appModel.selectedPage = pages[max(pages.startIndex, index - 1)]
    }

    private func selectNextPage() {
        let pages = AppPage.allCases
        guard let index = pages.firstIndex(of: appModel.selectedPage) else {
            return
        }

        appModel.selectedPage = pages[min(pages.index(before: pages.endIndex), index + 1)]
    }

    private var isFirstPage: Bool {
        appModel.selectedPage == AppPage.allCases.first
    }

    private var isLastPage: Bool {
        appModel.selectedPage == AppPage.allCases.last
    }
}

private enum PopoverChrome {
    static let headerHeight: CGFloat = 47
    static let dividerHeight: CGFloat = 1
    static let footerHeight: CGFloat = 28
    static let contentHeight: CGFloat = LayoutMetrics.popoverHeight - headerHeight - dividerHeight - footerHeight
}

private struct PixelPageIndicator: View {
    @Binding var selection: AppPage

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppPage.allCases) { page in
                Button {
                    withAnimation(.easeOut(duration: 0.12)) {
                        selection = page
                    }
                } label: {
                    if selection == page {
                        Text(page.title)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .padding(.horizontal, 5)
                            .frame(height: 15)
                            .background(HVColor.primaryText)
                    } else {
                        Rectangle()
                            .fill(HVColor.primaryText.opacity(0.42))
                            .frame(width: 5, height: 5)
                            .frame(width: 12, height: 15)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(page.title)
            }
        }
    }
}

private struct PixelArrowButton: View {
    let label: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(isDisabled ? HVColor.mutedText.opacity(0.35) : HVColor.primaryText)
                .frame(width: 24, height: 20)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
