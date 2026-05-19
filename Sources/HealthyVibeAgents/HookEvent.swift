import Foundation

public struct HookEvent: Codable, Equatable, Identifiable {
    public let id: String
    public let source: String
    public let event: String
    public let receivedAt: Date

    public init(id: String, source: String, event: String, receivedAt: Date) {
        self.id = id
        self.source = source
        self.event = event
        self.receivedAt = receivedAt
    }
}

struct HookEventEnvelope: Codable {
    let source: String
    let event: String
    let receivedAt: Date
}
