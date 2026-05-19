import SwiftUI
import HealthyVibeCore

struct CalendarPageView: View {
    @EnvironmentObject private var appModel: AppModel
    private let calendar = Calendar.current
    private let referenceDate = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: HVSpacing.large) {
            HStack {
                Text(monthTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HVColor.primaryText)

                Spacer()

                Text("本地历史")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HVColor.secondaryText)
            }

            calendarGrid

            VStack(alignment: .leading, spacing: HVSpacing.small) {
                metricRow(title: "今日", value: "\(appModel.historyOverview.todayMinutes) 分钟")
                metricRow(title: "连续", value: "\(appModel.historyOverview.currentStreakDays) 天")
                metricRow(title: "累计", value: LongevityCopy.totalLine(forTotalMinutes: appModel.historyOverview.totalLongevityMinutes))
            }
            .padding(.top, HVSpacing.small)

            selectedDayDetail

            Spacer(minLength: 0)
        }
        .padding(HVSpacing.large)
        .onAppear {
            appModel.refreshForCurrentDay()
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy 年 M 月"
        return formatter.string(from: referenceDate)
    }

    private var calendarGrid: some View {
        VStack(spacing: HVSpacing.small) {
            HStack {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(HVColor.mutedText)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 7) {
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let dateKey = dateKey(forDay: day)
                        CalendarDayCell(
                            day: day,
                            isToday: day == currentDay,
                            isSelected: appModel.selectedHistoryDateKey == dateKey,
                            summary: appModel.historySummary(for: dateKey)
                        ) {
                            appModel.selectedHistoryDateKey = dateKey
                        }
                    } else {
                        Color.clear
                            .frame(height: 24)
                    }
                }
            }
        }
    }

    private var monthCells: [Int?] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: referenceDate),
            let range = calendar.range(of: .day, in: .month, for: referenceDate)
        else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let mondayBasedOffset = (firstWeekday + 5) % 7
        var cells: [Int?] = Array(repeating: nil, count: mondayBasedOffset)
        cells.append(contentsOf: range.map(Optional.some))

        while cells.count % 7 != 0 {
            cells.append(nil)
        }

        return cells
    }

    private var currentDay: Int {
        calendar.component(.day, from: referenceDate)
    }

    private var selectedDayDetail: some View {
        let dateKey = appModel.selectedHistoryDateKey ?? dateKey(forDay: currentDay)
        let summary = appModel.historySummary(for: dateKey)

        return VStack(alignment: .leading, spacing: HVSpacing.xsmall) {
            Text(dayTitle(for: dateKey))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HVColor.primaryText)
            Text("延寿 \(summary?.longevityMinutes ?? 0) 分钟 · 完成 \(summary?.completedTaskCount ?? 0) 次任务")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HVColor.secondaryText)
        }
        .padding(.horizontal, HVSpacing.medium)
        .padding(.vertical, HVSpacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HVColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: HVRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HVRadius.medium, style: .continuous)
                .stroke(HVColor.border, lineWidth: 1)
        )
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HVColor.secondaryText)
                .frame(width: 36, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HVColor.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func dateKey(forDay day: Int) -> String {
        let components = calendar.dateComponents([.year, .month], from: referenceDate)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func dayTitle(for dateKey: String) -> String {
        let parts = dateKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else {
            return dateKey
        }

        return "\(parts[1]) 月 \(parts[2]) 日"
    }
}

private struct CalendarDayCell: View {
    let day: Int
    let isToday: Bool
    let isSelected: Bool
    let summary: DailyHistorySummary?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: HVRadius.small, style: .continuous)
                    .fill(backgroundColor)

                Text("\(day)")
                    .font(.system(size: 12, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(isToday ? HVColor.primaryText : HVColor.secondaryText)

                if summary?.hasRecord == true {
                    Circle()
                        .fill(summary?.reachedGoal == true ? HVColor.calmAccent : HVColor.warmAccent.opacity(0.65))
                        .frame(width: 4, height: 4)
                        .offset(y: 8)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 24)
        .overlay(
            RoundedRectangle(cornerRadius: HVRadius.small, style: .continuous)
                .stroke(isSelected ? HVColor.warmAccent : Color.clear, lineWidth: 1)
        )
    }

    private var backgroundColor: Color {
        if isSelected {
            return HVColor.accentFill.opacity(0.85)
        }

        if isToday {
            return HVColor.accentFill
        }

        return Color.clear
    }
}
