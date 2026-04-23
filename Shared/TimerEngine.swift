import Foundation
import Combine

@MainActor
public final class TimerEngine: ObservableObject {
    @Published public private(set) var state: TimerState
    @Published public private(set) var now: Date

    private var pendingEvents: [(fireDate: Date, event: SignalEvent)] = []
    private let signaler: SignalPlaying
    private let clock: () -> Date
    private var tickTimer: Timer?
    private let onStateChange: ((TimerState) -> Void)?

    public init(
        state: TimerState = .initial,
        signaler: SignalPlaying,
        clock: @escaping () -> Date = { Date() },
        onStateChange: ((TimerState) -> Void)? = nil
    ) {
        self.state = state
        self.signaler = signaler
        self.clock = clock
        self.now = clock()
        self.onStateChange = onStateChange
    }

    public var remaining: TimeInterval { state.remaining(at: now) }

    public var isCountingDown: Bool { state.isCountingDown(at: now) }
    public var isCountingUp: Bool { state.isCountingUp(at: now) }
    public var isIdle: Bool { state.mode == .idle }

    public func setDuration(_ duration: StartDuration) {
        guard state.mode == .idle else { return }
        state.duration = duration
        state.updatedAt = clock()
        notifyChange()
    }

    public func start() {
        guard state.mode == .idle else { return }
        let startMoment = clock()
        state.zeroDate = startMoment.addingTimeInterval(TimeInterval(state.duration.rawValue))
        state.mode = .running
        state.updatedAt = startMoment
        now = startMoment
        recomputeSchedule()
        startTicking()
        notifyChange()
    }

    public func plusOne() {
        guard state.mode == .running, let z = state.zeroDate else { return }
        let moment = clock()
        guard z.timeIntervalSince(moment) > 0 else { return }
        state.zeroDate = z.addingTimeInterval(60)
        state.updatedAt = moment
        recomputeSchedule()
        notifyChange()
    }

    public func minusOne() {
        guard state.mode == .running, let z = state.zeroDate else { return }
        let moment = clock()
        let remainingNow = z.timeIntervalSince(moment)
        guard remainingNow >= 60 else { return }
        state.zeroDate = z.addingTimeInterval(-60)
        state.updatedAt = moment
        recomputeSchedule()
        notifyChange()
    }

    public func sync() {
        guard state.mode == .running, let z = state.zeroDate else { return }
        let moment = clock()
        let remainingNow = z.timeIntervalSince(moment)
        guard remainingNow >= 60 else { return }
        let flooredMinutes = floor(remainingNow / 60.0)
        state.zeroDate = moment.addingTimeInterval(flooredMinutes * 60.0)
        state.updatedAt = moment
        recomputeSchedule()
        notifyChange()
    }

    public func reset() {
        let moment = clock()
        state.mode = .idle
        state.zeroDate = nil
        state.updatedAt = moment
        pendingEvents.removeAll()
        stopTicking()
        now = moment
        notifyChange()
    }

    public func apply(remoteState: TimerState) {
        guard remoteState.updatedAt > state.updatedAt else { return }
        state = remoteState
        if state.mode == .running {
            recomputeSchedule()
            startTicking()
        } else {
            pendingEvents.removeAll()
            stopTicking()
        }
    }

    // MARK: - Testable advance

    internal func advance(to moment: Date) {
        now = moment
        while let first = pendingEvents.first, first.fireDate <= moment {
            signaler.play(first.event.kind)
            pendingEvents.removeFirst()
        }
    }

    internal var pendingEventCount: Int { pendingEvents.count }

    // MARK: - Private

    private func recomputeSchedule() {
        pendingEvents.removeAll()
        guard let z = state.zeroDate else { return }
        let all = SignalSchedule.events(for: state.duration)
        let cutoff = clock()
        for ev in all {
            let fireDate = z.addingTimeInterval(-TimeInterval(ev.secondsBeforeZero))
            if fireDate >= cutoff {
                pendingEvents.append((fireDate, ev))
            }
        }
        pendingEvents.sort { $0.fireDate < $1.fireDate }
    }

    private func startTicking() {
        stopTicking()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
    }

    private func stopTicking() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tick() {
        advance(to: clock())
    }

    private func notifyChange() {
        onStateChange?(state)
    }
}
