import Foundation

public struct TaskEngine {
    private let calendar: Calendar
    private let templates: [TaskTemplate]
    private let chooseCandidateIndex: ([Int]) -> Int

    public init(
        calendar: Calendar = .current,
        templates: [TaskTemplate] = TaskTemplate.defaultTemplates,
        chooseCandidateIndex: @escaping ([Int]) -> Int = { candidates in
            candidates.randomElement() ?? candidates[0]
        }
    ) {
        self.calendar = calendar
        self.templates = templates
        self.chooseCandidateIndex = chooseCandidateIndex
    }

    public func makeInitialState(for date: Date = Date(), targetMinutes: Int = 30) -> TodayTaskState {
        TodayTaskState(
            dateKey: dateKey(for: date),
            items: templates.map { DailyTaskItem(template: $0) },
            targetMinutes: targetMinutes
        )
    }

    public func ensureCurrentDay(in state: inout TodayTaskState, now: Date = Date()) {
        let currentDateKey = dateKey(for: now)
        guard state.dateKey != currentDateKey else {
            return
        }

        state = makeInitialState(for: now, targetMinutes: state.targetMinutes)
    }

    @discardableResult
    public func deliverTask(in state: inout TodayTaskState, now: Date = Date()) -> DailyTaskItem? {
        ensureCurrentDay(in: &state, now: now)

        guard let chosenIndex = chooseIndex(from: candidateIndices(in: state)) else {
            state.currentTaskID = nil
            state.lastCompletion = nil
            return nil
        }

        state.currentTaskID = state.items[chosenIndex].id
        state.lastCompletion = nil
        return state.items[chosenIndex]
    }

    @discardableResult
    public func switchTask(in state: inout TodayTaskState, now: Date = Date()) -> DailyTaskItem? {
        ensureCurrentDay(in: &state, now: now)

        let allCandidates = candidateIndices(in: state)
        guard !allCandidates.isEmpty else {
            state.currentTaskID = nil
            return nil
        }

        let currentTaskID = state.currentTaskID
        let candidatesExcludingCurrent = allCandidates.filter { state.items[$0].id != currentTaskID }
        let candidates = candidatesExcludingCurrent.isEmpty ? allCandidates : candidatesExcludingCurrent

        guard let chosenIndex = chooseIndex(from: candidates) else {
            return nil
        }

        state.currentTaskID = state.items[chosenIndex].id
        state.lastCompletion = nil
        return state.items[chosenIndex]
    }

    @discardableResult
    public func completeCurrentTask(in state: inout TodayTaskState, now: Date = Date()) -> TaskCompletionSummary? {
        ensureCurrentDay(in: &state, now: now)

        guard
            let currentTaskID = state.currentTaskID,
            let index = state.items.firstIndex(where: { $0.id == currentTaskID && !$0.isDepleted })
        else {
            return nil
        }

        state.items[index].completedCount += 1
        let template = state.items[index].template
        let summary = TaskCompletionSummary(
            templateID: template.id,
            title: template.title,
            rewardMinutes: template.rewardMinutes,
            totalLongevityMinutes: state.totalLongevityMinutes,
            completedAt: now
        )

        state.currentTaskID = nil
        state.lastCompletion = summary
        return summary
    }

    public func dateKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func candidateIndices(in state: TodayTaskState) -> [Int] {
        Array(state.items.indices).filter { !state.items[$0].isDepleted }
    }

    private func chooseIndex(from candidates: [Int]) -> Int? {
        guard !candidates.isEmpty else {
            return nil
        }

        let chosen = chooseCandidateIndex(candidates)
        return candidates.contains(chosen) ? chosen : candidates[0]
    }
}
