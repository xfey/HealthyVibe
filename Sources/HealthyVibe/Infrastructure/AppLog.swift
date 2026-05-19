import OSLog

enum AppLog {
    static let app = Logger(subsystem: "com.flintstudio.healthyvibe", category: "app")
    static let ui = Logger(subsystem: "com.flintstudio.healthyvibe", category: "ui")
    static let storage = Logger(subsystem: "com.flintstudio.healthyvibe", category: "storage")
}
