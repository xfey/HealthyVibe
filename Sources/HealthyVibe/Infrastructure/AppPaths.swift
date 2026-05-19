import Foundation

struct AppPaths {
    let applicationSupportDirectory: URL
    let eventsDirectory: URL
    let hooksDirectory: URL
    let databaseURL: URL

    init(fileManager: FileManager = .default) {
        let supportRoot = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)

        self.applicationSupportDirectory = supportRoot.appendingPathComponent("HealthyVibe", isDirectory: true)
        self.eventsDirectory = applicationSupportDirectory.appendingPathComponent("events", isDirectory: true)
        self.hooksDirectory = applicationSupportDirectory.appendingPathComponent("hooks", isDirectory: true)
        self.databaseURL = applicationSupportDirectory.appendingPathComponent("HealthyVibe.sqlite", isDirectory: false)
    }

    func ensureCreated(fileManager: FileManager = .default) throws {
        try fileManager.createDirectory(at: applicationSupportDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: eventsDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: hooksDirectory, withIntermediateDirectories: true)
    }
}
