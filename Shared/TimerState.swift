import Foundation

public enum TimerMode: String, Codable, Sendable, Equatable {
    case idle
    case running
}

public enum StartDuration: Int, Codable, CaseIterable, Sendable, Identifiable {
    case threeMinutes = 180
    case fiveMinutes = 300

    public var id: Int { rawValue }
    public var displayName: String {
        switch self {
        case .threeMinutes: return "3 min"
        case .fiveMinutes: return "5 min"
        }
    }
}

public struct TimerState: Codable, Equatable, Sendable {
    public var mode: TimerMode
    public var duration: StartDuration
    public var zeroDate: Date?
    public var updatedAt: Date

    public init(
        mode: TimerMode = .idle,
        duration: StartDuration = .threeMinutes,
        zeroDate: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.mode = mode
        self.duration = duration
        self.zeroDate = zeroDate
        self.updatedAt = updatedAt
    }

    public static let initial = TimerState()
}

public extension TimerState {
    func remaining(at now: Date) -> TimeInterval {
        guard let z = zeroDate else { return TimeInterval(duration.rawValue) }
        return z.timeIntervalSince(now)
    }

    func isCountingDown(at now: Date) -> Bool {
        mode == .running && remaining(at: now) > 0
    }

    func isCountingUp(at now: Date) -> Bool {
        mode == .running && remaining(at: now) <= 0
    }
}
