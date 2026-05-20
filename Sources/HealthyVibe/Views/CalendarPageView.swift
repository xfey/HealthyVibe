import SwiftUI
import HealthyVibeCore

struct CalendarPageView: View {
    @EnvironmentObject private var appModel: AppModel
    private let calendar = Calendar.current
    private let referenceDate = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(monthTitle)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(HVColor.primaryText)

                Spacer()
            }

            Text(LongevityCopy.totalLine(forTotalMinutes: appModel.historyOverview.totalLongevityMinutes))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(HVColor.secondaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
                .fixedSize(horizontal: false, vertical: true)

            calendarGrid

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 2)
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
        VStack(spacing: 3) {
            HStack {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(HVColor.mutedText)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
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
                            .frame(height: 13)
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

    private func dateKey(forDay day: Int) -> String {
        let components = calendar.dateComponents([.year, .month], from: referenceDate)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
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
                    .font(.system(size: 9, weight: isToday ? .bold : .medium, design: .monospaced))
                    .foregroundStyle(isToday ? HVColor.primaryText : HVColor.secondaryText)

                if summary?.hasRecord == true {
                    Rectangle()
                        .fill(summary?.reachedGoal == true ? HVColor.calmAccent : HVColor.warmAccent.opacity(0.65))
                        .frame(width: 3, height: 3)
                        .offset(y: 4.5)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 13)
        .overlay(
            Rectangle()
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
