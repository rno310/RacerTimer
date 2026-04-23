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

        shortTone = makeTone(duration: 0.25, format: format)
        longTone  = makeTone(duration: 1.0,  format: format)
        startTone = makeTone(duration: 3.0,  format: format)
        gap       = makeSilence(duration: 0.12, format: format)
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
            hapticStrong()
        case .short:
            schedule(shortTone)
            hapticLight()
        case .shortBurst(let count):
            for i in 0..<count {
                if i > 0 { schedule(gap) }
                schedule(shortTone)
            }
            hapticLight()
        case .longPlusShorts(let count):
            schedule(longTone)
            for _ in 0..<count {
                schedule(gap)
                schedule(shortTone)
            }
            hapticStrong()
        case .startSignal:
            schedule(startTone)
            hapticStrong()
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
        WKInterfaceDevice.current().play(.click)
        #elseif os(iOS)
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred()
        #endif
    }
}
