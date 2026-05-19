import AppKit
import Foundation
import HealthyVibeCore

@MainActor
final class ActiveTimeTracker {
    var onFallbackDue: (() -> Void)?

    private var accumulator: ActiveTimeAccumulator
    private var timer: Timer?
    private var lastTickDate: Date?
    private var observerTokens: [NSObjectProtocol] = []

    init(fallbackInterval: TimeInterval = 60 * 60) {
        self.accumulator = ActiveTimeAccumulator(fallbackInterval: fallbackInterval)
    }

    func start() {
        guard timer == nil else {
            return
        }

        lastTickDate = Date()
        installWorkspaceObservers()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        lastTickDate = nil

        let notificationCenter = NSWorkspace.shared.notificationCenter
        for token in observerTokens {
            notificationCenter.removeObserver(token)
        }
        observerTokens.removeAll()
    }

    func recordHookEvent() {
        accumulator.recordHookEvent()
        lastTickDate = Date()
    }

    private func tick() {
        let now = Date()
        defer {
            lastTickDate = now
        }

        guard let lastTickDate else {
            return
        }

        let didReachFallback = accumulator.advance(by: now.timeIntervalSince(lastTickDate))
        if didReachFallback {
            onFallbackDue?()
        }
    }

    private func pause() {
        tick()
        accumulator.setActive(false)
        lastTickDate = nil
    }

    private func resume() {
        accumulator.setActive(true)
        lastTickDate = Date()
    }

    private func installWorkspaceObservers() {
        let notificationCenter = NSWorkspace.shared.notificationCenter

        observerTokens.append(notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.pause() }
        })

        observerTokens.append(notificationCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.pause() }
        })

        observerTokens.append(notificationCenter.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.pause() }
        })

        observerTokens.append(notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.resume() }
        })

        observerTokens.append(notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.resume() }
        })

        observerTokens.append(notificationCenter.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.resume() }
        })
    }

    deinit {
        timer?.invalidate()
        let notificationCenter = NSWorkspace.shared.notificationCenter
        for token in observerTokens {
            notificationCenter.removeObserver(token)
        }
    }
}
