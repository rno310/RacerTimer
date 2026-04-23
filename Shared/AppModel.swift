import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppModel: ObservableObject {
    public let engine: TimerEngine
    public let bridge: ConnectivityBridge

    private var cancellables: Set<AnyCancellable> = []

    public init() {
        let signaler = AudioHapticSignaler()
        let bridge = ConnectivityBridge()
        let engine = TimerEngine(
            signaler: signaler,
            onStateChange: { newState in
                bridge.send(state: newState)
            }
        )
        self.engine = engine
        self.bridge = bridge

        bridge.onRemoteState = { [weak engine] remoteState in
            engine?.apply(remoteState: remoteState)
        }
        bridge.activate()

        // Re-broadcast engine changes through AppModel so views observing us refresh.
        engine.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
