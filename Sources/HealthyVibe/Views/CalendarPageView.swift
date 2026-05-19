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
                metricRow(title: "今日", value: "\(appModel.todayTaskState.totalLongevityMinutes) 分钟")
                metricRow(title: "连续", value: appModel.todayTaskState.completedTaskCount > 0 ? "1 天" : "0 天")
                metricRow(title: "累计", value: LongevityCopy.totalLine(forTotalMinutes: appModel.todayTaskState.totalLongevityMinutes))
            }
            .padding(.top, HVSpacing.small)

            Spacer(minLength: 0)
        }
        .padding(HVSpacing.large)
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
                ForEach(monthCells, id: \.self) { day in
                    CalendarDayCell(day: day, isToday: day == currentDay)
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

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HVColor.secondaryText)
                .frame(width: 36, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HVColor.primaryText)
            Spacer(minLength: 0)
        }
    }
}

private struct CalendarDayCell: View {
    let day: Int?
    let isToday: Bool

    var body: some View {
        ZStack {
            if let day {
                RoundedRectangle(cornerRadius: HVRadius.small, style: .continuous)
                    .fill(isToday ? HVColor.accentFill : Color.clear)

                Text("\(day)")
                    .font(.system(size: 12, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(isToday ? HVColor.primaryText : HVColor.secondaryText)
            }
        }
        .frame(height: 24)
    }
}
