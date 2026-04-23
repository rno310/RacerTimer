import Foundation

@MainActor
final class RecordingSignaler: SignalPlaying {
    private(set) var played: [SignalKind] = []

    func play(_ kind: SignalKind) {
        played.append(kind)
    }

    func reset() {
        played.removeAll()
    }
}
