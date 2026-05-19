import Foundation

public struct ActiveTimeAccumulator: Equatable {
    public let fallbackInterval: TimeInterval
    public private(set) var activeSecondsSinceHook: TimeInterval
    public private(set) var isActive: Bool

    public init(
        fallbackInterval: TimeInterval = 60 * 60,
        activeSecondsSinceHook: TimeInterval = 0,
        isActive: Bool = true
    ) {
        self.fallbackInterval = fallbackInterval
        self.activeSecondsSinceHook = activeSecondsSinceHook
        self.isActive = isActive
    }

    public mutating func setActive(_ isActive: Bool) {
        self.isActive = isActive
    }

    public mutating func recordHookEvent() {
        activeSecondsSinceHook = 0
    }

    @discardableResult
    public mutating func advance(by seconds: TimeInterval) -> Bool {
        guard isActive else {
            return false
        }

        activeSecondsSinceHook += max(0, seconds)

        guard activeSecondsSinceHook >= fallbackInterval else {
            return false
        }

        activeSecondsSinceHook = 0
        return true
    }
}
