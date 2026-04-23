import Foundation

public enum SignalKind: Sendable, Equatable {
    case long
    case short
    case shortBurst(count: Int)
    case longPlusShorts(count: Int)
    case startSignal
}

public struct SignalEvent: Sendable, Equatable {
    public let secondsBeforeZero: Int
    public let kind: SignalKind
}

public enum SignalSchedule {
    public static func events(for duration: StartDuration) -> [SignalEvent] {
        var events: [SignalEvent] = []

        var t = duration.rawValue
        while t >= 120 {
            events.append(SignalEvent(secondsBeforeZero: t, kind: .long))
            t -= 60
        }

        events.append(SignalEvent(secondsBeforeZero: 90, kind: .longPlusShorts(count: 3)))
        events.append(SignalEvent(secondsBeforeZero: 60, kind: .long))
        events.append(SignalEvent(secondsBeforeZero: 30, kind: .shortBurst(count: 3)))
        events.append(SignalEvent(secondsBeforeZero: 20, kind: .shortBurst(count: 2)))
        events.append(SignalEvent(secondsBeforeZero: 10, kind: .shortBurst(count: 1)))

        for s in stride(from: 5, through: 1, by: -1) {
            events.append(SignalEvent(secondsBeforeZero: s, kind: .short))
        }
        events.append(SignalEvent(secondsBeforeZero: 0, kind: .startSignal))

        return events.sorted { $0.secondsBeforeZero > $1.secondsBeforeZero }
    }
}
