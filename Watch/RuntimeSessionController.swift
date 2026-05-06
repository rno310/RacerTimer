import Foundation
import WatchKit

@MainActor
final class RuntimeSessionController: NSObject, ObservableObject {
    private var session: WKExtendedRuntimeSession?
    private var autoStopTask: Task<Void, Never>?

    func start(autoStopAt: Date? = nil) {
        if let session, session.state == .running || session.state == .scheduled {
            scheduleAutoStop(at: autoStopAt)
            return
        }
        let s = WKExtendedRuntimeSession()
        s.delegate = self
        s.start()
        session = s
        scheduleAutoStop(at: autoStopAt)
    }

    func stop() {
        autoStopTask?.cancel()
        autoStopTask = nil
        guard let s = session else { return }
        if s.state == .running || s.state == .scheduled {
            s.invalidate()
        }
        session = nil
    }

    private func scheduleAutoStop(at date: Date?) {
        autoStopTask?.cancel()
        guard let date else { autoStopTask = nil; return }
        autoStopTask = Task { @MainActor [weak self] in
            let delay = date.timeIntervalSinceNow
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            if Task.isCancelled { return }
            self?.stop()
        }
    }
}

extension RuntimeSessionController: WKExtendedRuntimeSessionDelegate {
    nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    nonisolated func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.session === extendedRuntimeSession {
                self.session = nil
            }
        }
    }
}
