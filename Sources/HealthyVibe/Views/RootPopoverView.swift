import SwiftUI

struct RootPopoverView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .overlay(HVColor.border)
            pageContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: LayoutMetrics.popoverWidth, height: LayoutMetrics.popoverHeight)
        .background(HVColor.background)
        .gesture(pageSwipeGesture)
        .onMoveCommand(perform: moveSelection)
    }

    private var header: some View {
        VStack(spacing: HVSpacing.medium) {
            HStack(spacing: HVSpacing.small) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HVColor.warmAccent)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Vibe延寿指南")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(HVColor.primaryText)
                    Text("AI 写代码时，你去续命")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(HVColor.secondaryText)
                }

                Spacer(minLength: HVSpacing.small)
            }

            PageTabs(selection: $appModel.selectedPage)
        }
        .padding(.horizontal, HVSpacing.large)
        .padding(.top, HVSpacing.large)
        .padding(.bottom, HVSpacing.medium)
        .background(HVColor.surface)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch appModel.selectedPage {
        case .today:
            TodayTaskPageView()
        case .calendar:
            CalendarPageView()
        case .settings:
            SettingsPageView()
        }
    }

    private var pageSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 32)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else {
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
}

private struct PageTabs: View {
    @Binding var selection: AppPage

    var body: some View {
        HStack(spacing: 3) {
            ForEach(AppPage.allCases) { page in
                Button {
                    selection = page
                } label: {
                    Label(page.title, systemImage: page.systemImageName)
                        .labelStyle(.titleAndIcon)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PageTabButtonStyle(isSelected: selection == page))
            }
        }
        .padding(3)
        .background(HVColor.background)
        .clipShape(RoundedRectangle(cornerRadius: HVRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HVRadius.medium, style: .continuous)
                .stroke(HVColor.border, lineWidth: 1)
        )
    }
}

private struct PageTabButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(isSelected ? HVColor.primaryText : HVColor.secondaryText)
            .padding(.horizontal, HVSpacing.small)
            .frame(height: 28)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: HVRadius.small, style: .continuous))
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isSelected {
            return isPressed ? HVColor.accentFill.opacity(0.82) : HVColor.surface
        }

        return isPressed ? HVColor.border.opacity(0.35) : Color.clear
    }
}
