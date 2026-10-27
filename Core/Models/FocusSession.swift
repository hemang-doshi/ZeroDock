import Foundation

/// A deadline, not a ticking counter: no background task is needed for accuracy.
struct FocusSession: Codable, Equatable {
    private(set) var duration: TimeInterval = 1500
    private(set) var pausedRemaining: TimeInterval = 1500
    private(set) var deadline: Date?

    func remaining(at now: Date) -> TimeInterval {
        max(0, deadline.map { $0.timeIntervalSince(now) } ?? pausedRemaining)
    }

    func isRunning(at now: Date) -> Bool { deadline != nil && remaining(at: now) > 0 }

    mutating func start(at now: Date) {
        guard !isRunning(at: now) else { return }
        let seconds = remaining(at: now)
        deadline = now.addingTimeInterval(seconds > 0 ? seconds : duration)
    }

    mutating func pause(at now: Date) {
        pausedRemaining = remaining(at: now)
        deadline = nil
    }

    mutating func reset(minutes: Int? = nil) {
        if let minutes { duration = TimeInterval(min(180, max(1, minutes)) * 60) }
        pausedRemaining = duration
        deadline = nil
    }
}
