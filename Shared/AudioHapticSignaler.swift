import Foundation
import AVFoundation

#if os(watchOS)
import WatchKit
#elseif os(iOS)
import UIKit
#endif

@MainActor
public protocol SignalPlaying: AnyObject {
    func play(_ kind: SignalKind)
}

@MainActor
public final class AudioHapticSignaler: SignalPlaying {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private let toneFrequency: Double = 880

    private let shortDuration: Double = 0.25
    private let longDuration: Double = 1.0
    private let gapDuration: Double = 0.12

    private var shortTone: AVAudioPCMBuffer?
    private var longTone: AVAudioPCMBuffer?
    private var startTone: AVAudioPCMBuffer?
    private var gap: AVAudioPCMBuffer?

    public init() {
        configureAudioSession()
        setupEngine()
    }

    private func configureAudioSession() {
        #if os(iOS) || os(watchOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true, options: [])
        #endif
    }

    private func setupEngine() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
        } catch {
            return
        }
        player.play()

        shortTone = makeTone(duration: shortDuration, format: format)
        longTone  = makeTone(duration: longDuration,  format: format)
        startTone = makeTone(duration: 3.0,           format: format)
        gap       = makeSilence(duration: gapDuration, format: format)
    }

    private func makeTone(duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let samples = buffer.floatChannelData?[0] else { return nil }

        let amplitude: Float = 0.7
        let attackSamples = Int(0.006 * sampleRate)
        let total = Int(frameCount)
        for i in 0..<total {
            let t = Double(i) / sampleRate
            var envelope: Float = 1.0
            if i < attackSamples {
                envelope = Float(i) / Float(attackSamples)
            } else if i > total - attackSamples {
                envelope = Float(total - i) / Float(attackSamples)
            }
            samples[i] = amplitude * envelope * Float(sin(2.0 * .pi * toneFrequency * t))
        }
        return buffer
    }

    private func makeSilence(duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        return buffer
    }

    public func play(_ kind: SignalKind) {
        switch kind {
        case .long:
            schedule(longTone)
            playHaptics([(0, true)])
        case .short:
            schedule(shortTone)
            playHaptics([(0, false)])
        case .shortBurst(let count):
            var pattern: [(delay: Double, strong: Bool)] = []
            var t: Double = 0
            for i in 0..<count {
                if i > 0 { t += gapDuration }
                pattern.append((t, false))
                schedule(i > 0 ? gap : nil)
                schedule(shortTone)
                t += shortDuration
            }
            playHaptics(pattern)
        case .longsPlusShorts(let longs, let shorts):
            var pattern: [(delay: Double, strong: Bool)] = []
            var t: Double = 0
            for i in 0..<longs {
                if i > 0 { t += gapDuration; schedule(gap) }
                pattern.append((t, true))
                schedule(longTone)
                t += longDuration
            }
            for _ in 0..<shorts {
                t += gapDuration
                schedule(gap)
                pattern.append((t, false))
                schedule(shortTone)
                t += shortDuration
            }
            playHaptics(pattern)
        case .startSignal:
            schedule(startTone)
            playHaptics([(0, true)])
        }
    }

    private func playHaptics(_ events: [(delay: Double, strong: Bool)]) {
        Task { @MainActor [weak self] in
            var elapsed: Double = 0
            for event in events {
                let wait = event.delay - elapsed
                if wait > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
                elapsed = event.delay
                guard let self else { return }
                if event.strong {
                    self.hapticStrong()
                } else {
                    self.hapticLight()
                }
            }
        }
    }

    private func schedule(_ buffer: AVAudioPCMBuffer?) {
        guard let buffer else { return }
        if !engine.isRunning {
            try? engine.start()
            player.play()
        }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    private func hapticStrong() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.notification)
        #elseif os(iOS)
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.prepare()
        gen.impactOccurred()
        #endif
    }

    private func hapticLight() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #elseif os(iOS)
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred()
        #endif
    }
}
