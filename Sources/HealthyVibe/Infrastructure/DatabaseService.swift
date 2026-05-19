import Foundation

protocol DatabaseService {
    func bootstrap() throws
}

struct PlaceholderDatabaseService: DatabaseService {
    let paths: AppPaths

    func bootstrap() throws {
        AppLog.storage.info("Database layer reserved at \(paths.databaseURL.path, privacy: .private).")
    }
}
