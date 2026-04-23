import Foundation
import WatchConnectivity

@MainActor
public final class ConnectivityBridge: NSObject, ObservableObject {
    public typealias Handler = (TimerState) -> Void

    private let session: WCSession
    public var onRemoteState: Handler?

    public override init() {
        self.session = WCSession.default
        super.init()
    }

    public func activate() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    public func send(state: TimerState) {
        guard WCSession.isSupported() else { return }
        guard session.activationState == .activated else { return }

        let payload: [String: Any] = encode(state)

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { _ in
                try? self.session.updateApplicationContext(payload)
            }
        } else {
            try? session.updateApplicationContext(payload)
        }
    }

    // MARK: - Encoding

    private func encode(_ state: TimerState) -> [String: Any] {
        var dict: [String: Any] = [
            "mode": state.mode.rawValue,
            "duration": state.duration.rawValue,
            "updatedAt": state.updatedAt.timeIntervalSince1970
        ]
        if let z = state.zeroDate {
            dict["zeroDate"] = z.timeIntervalSince1970
        }
        return dict
    }

    private func decode(_ dict: [String: Any]) -> TimerState? {
        guard
            let modeRaw = dict["mode"] as? String,
            let mode = TimerMode(rawValue: modeRaw),
            let durationRaw = dict["duration"] as? Int,
            let duration = StartDuration(rawValue: durationRaw),
            let updatedAtInterval = dict["updatedAt"] as? TimeInterval
        else { return nil }

        let zeroDate = (dict["zeroDate"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        return TimerState(
            mode: mode,
            duration: duration,
            zeroDate: zeroDate,
            updatedAt: Date(timeIntervalSince1970: updatedAtInterval)
        )
    }

    private func handleIncoming(_ dict: [String: Any]) {
        guard let state = decode(dict) else { return }
        onRemoteState?(state)
    }
}

extension ConnectivityBridge: WCSessionDelegate {
    nonisolated public func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}

    #if os(iOS)
    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif

    nonisolated public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let captured = message
        Task { @MainActor in
            self.handleIncoming(captured)
        }
    }

    nonisolated public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let captured = applicationContext
        Task { @MainActor in
            self.handleIncoming(captured)
        }
    }
}
