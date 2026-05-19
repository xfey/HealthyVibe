import Foundation
import GRDB
import HealthyVibeCore

public final class AppDatabase {
    private let dbQueue: DatabaseQueue
    private let taskEngine: TaskEngine
    private let calendar: Calendar
    private let isoFormatter = ISO8601DateFormatter()

    public init(
        path: String,
        calendar: Calendar = .current,
        taskEngine: TaskEngine? = nil
    ) throws {
        self.dbQueue = try DatabaseQueue(path: path)
        self.calendar = calendar
        self.taskEngine = taskEngine ?? TaskEngine(calendar: calendar)
        try Self.makeMigrator().migrate(dbQueue)
    }

    public init(
        inMemoryWith calendar: Calendar = .current,
        taskEngine: TaskEngine? = nil
    ) throws {
        self.dbQueue = try DatabaseQueue()
        self.calendar = calendar
        self.taskEngine = taskEngine ?? TaskEngine(calendar: calendar)
        try Self.makeMigrator().migrate(dbQueue)
    }

    public func loadTodayState(now: Date = Date()) throws -> TodayTaskState {
        try dbQueue.write { db in
            try bootstrapDefaults(db, now: now)
            let dateKey = taskEngine.dateKey(for: now)
            let targetMinutes = try readTargetMinutes(db, now: now)
            try ensureDailyPlan(db, dateKey: dateKey, targetMinutes: targetMinutes, now: now)
            return try fetchState(db, dateKey: dateKey)
        }
    }

    @discardableResult
    public func deliverTask(
        in state: inout TodayTaskState,
        source: String = "manual",
        now: Date = Date()
    ) throws -> DailyTaskItem? {
        var updatedState = state
        let deliveredItem = taskEngine.deliverTask(in: &updatedState, now: now)

        try dbQueue.write { db in
            if let deliveredItem {
                try insertDelivery(db, item: deliveredItem, dateKey: updatedState.dateKey, source: source, now: now)
            }

            try saveState(db, state: updatedState, lastCompletionID: nil, now: now)
        }

        state = updatedState
        return deliveredItem
    }

    @discardableResult
    public func switchTask(
        in state: inout TodayTaskState,
        now: Date = Date()
    ) throws -> DailyTaskItem? {
        var updatedState = state
        let deliveredItem = taskEngine.switchTask(in: &updatedState, now: now)

        try dbQueue.write { db in
            if let deliveredItem {
                try insertDelivery(db, item: deliveredItem, dateKey: updatedState.dateKey, source: "switch", now: now)
            }

            try saveState(db, state: updatedState, lastCompletionID: nil, now: now)
        }

        state = updatedState
        return deliveredItem
    }

    @discardableResult
    public func completeCurrentTask(
        in state: inout TodayTaskState,
        now: Date = Date()
    ) throws -> TaskCompletionSummary? {
        var updatedState = state
        guard let summary = taskEngine.completeCurrentTask(in: &updatedState, now: now) else {
            return nil
        }

        let completionID = UUID().uuidString
        try dbQueue.write { db in
            try insertCompletion(db, id: completionID, dateKey: updatedState.dateKey, summary: summary)
            try saveState(db, state: updatedState, lastCompletionID: completionID, now: now)
        }

        state = updatedState
        return summary
    }

    public func loadMonthSummaries(containing date: Date = Date()) throws -> [DailyHistorySummary] {
        guard let interval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }

        let startKey = taskEngine.dateKey(for: interval.start)
        let endDate = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.start
        let endKey = taskEngine.dateKey(for: endDate)

        return try dbQueue.read { db in
            try DailyHistorySummary.fetchAll(
                db,
                sql: """
                SELECT date, longevity_minutes, completed_task_count, target_minutes
                FROM daily_stats
                WHERE date BETWEEN ? AND ?
                  AND (longevity_minutes > 0 OR completed_task_count > 0)
                ORDER BY date
                """,
                arguments: [startKey, endKey]
            )
        }
    }

    public func loadHistoryOverview(now: Date = Date()) throws -> HistoryOverview {
        let todayKey = taskEngine.dateKey(for: now)

        return try dbQueue.read { db in
            let todayMinutes = try Int.fetchOne(
                db,
                sql: "SELECT longevity_minutes FROM daily_stats WHERE date = ?",
                arguments: [todayKey]
            ) ?? 0
            let totalMinutes = try Int.fetchOne(
                db,
                sql: "SELECT COALESCE(SUM(longevity_minutes), 0) FROM daily_stats"
            ) ?? 0
            let streakDays = try currentStreakDays(db, endingAt: now)

            return HistoryOverview(
                todayDateKey: todayKey,
                todayMinutes: todayMinutes,
                currentStreakDays: streakDays,
                totalLongevityMinutes: totalMinutes
            )
        }
    }

    public func clearAllData() throws {
        try dbQueue.write { db in
            for table in [
                "team_snapshots_cache",
                "team_profile",
                "hook_events",
                "task_completions",
                "task_deliveries",
                "daily_stats",
                "daily_task_plan",
                "app_settings",
                "task_templates"
            ] {
                try db.execute(sql: "DELETE FROM \(table)")
            }

            try bootstrapDefaults(db, now: Date())
        }
    }

    public func debugTableNames() throws -> Set<String> {
        try dbQueue.read { db in
            let names = try String.fetchAll(
                db,
                sql: "SELECT name FROM sqlite_master WHERE type = 'table'"
            )
            return Set(names)
        }
    }
}

extension DailyHistorySummary: FetchableRecord {
    public init(row: Row) {
        self.init(
            dateKey: row["date"],
            longevityMinutes: row["longevity_minutes"],
            completedTaskCount: row["completed_task_count"],
            targetMinutes: row["target_minutes"]
        )
    }
}

private extension AppDatabase {
    static func makeMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "task_templates", ifNotExists: true) { table in
                table.column("id", .text).primaryKey()
                table.column("title", .text).notNull()
                table.column("subtitle", .text).notNull()
                table.column("max_daily_count", .integer).notNull()
                table.column("reward_minutes", .integer).notNull()
                table.column("reward_suffix", .text).notNull()
                table.column("sort_order", .integer).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "daily_task_plan", ifNotExists: true) { table in
                table.column("date", .text).notNull()
                table.column("task_id", .text).notNull().references("task_templates", onDelete: .cascade)
                table.column("planned_count", .integer).notNull()
                table.column("completed_count", .integer).notNull().defaults(to: 0)
                table.column("reward_minutes", .integer).notNull()
                table.column("sort_order", .integer).notNull()
                table.primaryKey(["date", "task_id"])
            }

            try db.create(table: "task_deliveries", ifNotExists: true) { table in
                table.column("id", .text).primaryKey()
                table.column("date", .text).notNull()
                table.column("task_id", .text).notNull()
                table.column("delivered_at", .text).notNull()
                table.column("source", .text).notNull()
            }

            try db.create(table: "task_completions", ifNotExists: true) { table in
                table.column("id", .text).primaryKey()
                table.column("date", .text).notNull()
                table.column("task_id", .text).notNull()
                table.column("reward_minutes", .integer).notNull()
                table.column("completed_at", .text).notNull()
            }

            try db.create(table: "daily_stats", ifNotExists: true) { table in
                table.column("date", .text).primaryKey()
                table.column("longevity_minutes", .integer).notNull().defaults(to: 0)
                table.column("completed_task_count", .integer).notNull().defaults(to: 0)
                table.column("target_minutes", .integer).notNull()
                table.column("current_task_id", .text)
                table.column("last_completion_id", .text)
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "hook_events", ifNotExists: true) { table in
                table.column("id", .text).primaryKey()
                table.column("source", .text).notNull()
                table.column("event", .text).notNull()
                table.column("received_at", .text).notNull()
                table.column("processed_at", .text)
            }

            try db.create(table: "team_profile", ifNotExists: true) { table in
                table.column("id", .integer).primaryKey()
                table.column("team_code_hash", .text)
                table.column("member_id_hash", .text)
                table.column("display_name", .text)
                table.column("joined_at", .text)
            }

            try db.create(table: "team_snapshots_cache", ifNotExists: true) { table in
                table.column("team_code_hash", .text).notNull()
                table.column("member_id_hash", .text).notNull()
                table.column("display_name", .text)
                table.column("date", .text).notNull()
                table.column("longevity_minutes", .integer).notNull()
                table.column("completed_task_count", .integer).notNull()
                table.column("updated_at", .text).notNull()
                table.primaryKey(["team_code_hash", "member_id_hash", "date"])
            }

            try db.create(table: "app_settings", ifNotExists: true) { table in
                table.column("key", .text).primaryKey()
                table.column("value", .text).notNull()
                table.column("updated_at", .text).notNull()
            }
        }

        return migrator
    }

    func bootstrapDefaults(_ db: Database, now: Date) throws {
        try upsertTemplates(db, now: now)
        _ = try readTargetMinutes(db, now: now)
    }

    func upsertTemplates(_ db: Database, now: Date) throws {
        let updatedAt = isoString(now)

        for (index, template) in TaskTemplate.defaultTemplates.enumerated() {
            try db.execute(
                sql: """
                INSERT INTO task_templates (
                    id, title, subtitle, max_daily_count, reward_minutes, reward_suffix, sort_order, updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    title = excluded.title,
                    subtitle = excluded.subtitle,
                    max_daily_count = excluded.max_daily_count,
                    reward_minutes = excluded.reward_minutes,
                    reward_suffix = excluded.reward_suffix,
                    sort_order = excluded.sort_order,
                    updated_at = excluded.updated_at
                """,
                arguments: [
                    template.id,
                    template.title,
                    template.subtitle,
                    template.maxDailyCount,
                    template.rewardMinutes,
                    template.rewardSuffix,
                    index,
                    updatedAt
                ]
            )
        }
    }

    func readTargetMinutes(_ db: Database, now: Date) throws -> Int {
        if
            let value = try String.fetchOne(db, sql: "SELECT value FROM app_settings WHERE key = 'dailyTargetMinutes'"),
            let minutes = Int(value)
        {
            return minutes
        }

        try db.execute(
            sql: """
            INSERT INTO app_settings (key, value, updated_at)
            VALUES ('dailyTargetMinutes', '30', ?)
            ON CONFLICT(key) DO NOTHING
            """,
            arguments: [isoString(now)]
        )
        return 30
    }

    func ensureDailyPlan(
        _ db: Database,
        dateKey: String,
        targetMinutes: Int,
        now: Date
    ) throws {
        let count = try Int.fetchOne(
            db,
            sql: "SELECT COUNT(*) FROM daily_task_plan WHERE date = ?",
            arguments: [dateKey]
        ) ?? 0

        if count == 0 {
            for (index, template) in TaskTemplate.defaultTemplates.enumerated() {
                try db.execute(
                    sql: """
                    INSERT INTO daily_task_plan (
                        date, task_id, planned_count, completed_count, reward_minutes, sort_order
                    )
                    VALUES (?, ?, ?, 0, ?, ?)
                    """,
                    arguments: [
                        dateKey,
                        template.id,
                        template.maxDailyCount,
                        template.rewardMinutes,
                        index
                    ]
                )
            }
        }

        try db.execute(
            sql: """
            INSERT INTO daily_stats (
                date, longevity_minutes, completed_task_count, target_minutes, updated_at
            )
            VALUES (?, 0, 0, ?, ?)
            ON CONFLICT(date) DO NOTHING
            """,
            arguments: [dateKey, targetMinutes, isoString(now)]
        )
    }

    func fetchState(_ db: Database, dateKey: String) throws -> TodayTaskState {
        let rows = try Row.fetchAll(
            db,
            sql: """
            SELECT
                p.task_id,
                t.title,
                t.subtitle,
                p.planned_count,
                p.completed_count,
                p.reward_minutes,
                t.reward_suffix
            FROM daily_task_plan p
            JOIN task_templates t ON t.id = p.task_id
            WHERE p.date = ?
            ORDER BY p.sort_order
            """,
            arguments: [dateKey]
        )

        let items = rows.map { row in
            DailyTaskItem(
                template: TaskTemplate(
                    id: row["task_id"],
                    title: row["title"],
                    subtitle: row["subtitle"],
                    maxDailyCount: row["planned_count"],
                    rewardMinutes: row["reward_minutes"],
                    rewardSuffix: row["reward_suffix"]
                ),
                completedCount: row["completed_count"]
            )
        }

        let stats = try Row.fetchOne(
            db,
            sql: """
            SELECT target_minutes, current_task_id, last_completion_id
            FROM daily_stats
            WHERE date = ?
            """,
            arguments: [dateKey]
        )

        let targetMinutes: Int = stats?["target_minutes"] ?? 30
        let currentTaskID: String? = stats?["current_task_id"]
        let lastCompletionID: String? = stats?["last_completion_id"]
        let lastCompletion = try fetchCompletion(db, id: lastCompletionID)

        return TodayTaskState(
            dateKey: dateKey,
            items: items,
            currentTaskID: currentTaskID,
            lastCompletion: lastCompletion,
            targetMinutes: targetMinutes
        )
    }

    func fetchCompletion(_ db: Database, id: String?) throws -> TaskCompletionSummary? {
        guard let id else {
            return nil
        }

        guard let row = try Row.fetchOne(
            db,
            sql: """
            SELECT c.task_id, t.title, c.reward_minutes, c.completed_at
            FROM task_completions c
            LEFT JOIN task_templates t ON t.id = c.task_id
            WHERE c.id = ?
            """,
            arguments: [id]
        ) else {
            return nil
        }

        let completedAtString: String = row["completed_at"]
        let rewardMinutes: Int = row["reward_minutes"]
        let taskID: String = row["task_id"]
        let title: String = row["title"] ?? taskID

        let total = try Int.fetchOne(
            db,
            sql: "SELECT longevity_minutes FROM daily_stats WHERE last_completion_id = ?",
            arguments: [id]
        ) ?? rewardMinutes

        return TaskCompletionSummary(
            templateID: taskID,
            title: title,
            rewardMinutes: rewardMinutes,
            totalLongevityMinutes: total,
            completedAt: date(from: completedAtString)
        )
    }

    func saveState(
        _ db: Database,
        state: TodayTaskState,
        lastCompletionID: String?,
        now: Date
    ) throws {
        for item in state.items {
            try db.execute(
                sql: """
                UPDATE daily_task_plan
                SET completed_count = ?
                WHERE date = ? AND task_id = ?
                """,
                arguments: [item.completedCount, state.dateKey, item.id]
            )
        }

        try db.execute(
            sql: """
            UPDATE daily_stats
            SET
                longevity_minutes = ?,
                completed_task_count = ?,
                target_minutes = ?,
                current_task_id = ?,
                last_completion_id = ?,
                updated_at = ?
            WHERE date = ?
            """,
            arguments: [
                state.totalLongevityMinutes,
                state.completedTaskCount,
                state.targetMinutes,
                state.currentTask?.id,
                lastCompletionID,
                isoString(now),
                state.dateKey
            ]
        )
    }

    func insertDelivery(
        _ db: Database,
        item: DailyTaskItem,
        dateKey: String,
        source: String,
        now: Date
    ) throws {
        try db.execute(
            sql: """
            INSERT INTO task_deliveries (id, date, task_id, delivered_at, source)
            VALUES (?, ?, ?, ?, ?)
            """,
            arguments: [UUID().uuidString, dateKey, item.id, isoString(now), source]
        )
    }

    func insertCompletion(
        _ db: Database,
        id: String,
        dateKey: String,
        summary: TaskCompletionSummary
    ) throws {
        try db.execute(
            sql: """
            INSERT INTO task_completions (id, date, task_id, reward_minutes, completed_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            arguments: [
                id,
                dateKey,
                summary.templateID,
                summary.rewardMinutes,
                isoString(summary.completedAt)
            ]
        )
    }

    func currentStreakDays(_ db: Database, endingAt date: Date) throws -> Int {
        var streak = 0
        var cursor = calendar.startOfDay(for: date)

        while streak < 3660 {
            let dateKey = taskEngine.dateKey(for: cursor)
            let completedTaskCount = try Int.fetchOne(
                db,
                sql: "SELECT completed_task_count FROM daily_stats WHERE date = ?",
                arguments: [dateKey]
            ) ?? 0

            guard completedTaskCount > 0 else {
                break
            }

            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return streak
    }

    func isoString(_ date: Date) -> String {
        isoFormatter.string(from: date)
    }

    func date(from string: String) -> Date {
        isoFormatter.date(from: string) ?? Date(timeIntervalSince1970: 0)
    }
}
