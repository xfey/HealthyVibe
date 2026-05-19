import OSLog

enum AppLog {
    static let app = Logger(subsystem: "dev.healthyvibe.app", category: "app")
    static let ui = Logger(subsystem: "dev.healthyvibe.app", category: "ui")
    static let storage = Logger(subsystem: "dev.healthyvibe.app", category: "storage")
}
