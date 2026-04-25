import SwiftUI

struct TimerView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { ctx in
            let now = ctx.date
            let state = model.engine.state
            let remaining = state.remaining(at: now)
            let idle = model.engine.isIdle
            let flash = flashPhase(now: now)
            let bg = TimerDisplay.backgroundColor(remaining: remaining, idle: idle, flashOn: flash)
            let textColor = TimerDisplay.textColor(remaining: remaining, flashOn: flash)
            let text = TimerDisplay.format(remaining: remaining, idle: idle)
            let progress = TimerDisplay.fillProgress(remaining: remaining, duration: state.duration, idle: idle)

            let inFinalFlash = remaining > 0 && remaining <= 5
            let fill = inFinalFlash ? bg : TimerDisplay.fillColor(remaining: remaining, idle: idle)

            ZStack {
                bg.ignoresSafeArea()

                GeometryReader { geo in
                    Rectangle()
                        .fill(fill)
                        .frame(height: geo.size.height * progress)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .ignoresSafeArea()

                VStack(spacing: 2) {
                    Spacer(minLength: 0)

                    Text(text)
                        .font(.system(size: remaining > 0 ? 320 : 160, weight: .heavy).width(.compressed))
                        .monospacedDigit()
                        .foregroundColor(textColor)
                        .minimumScaleFactor(0.25)
                        .lineLimit(1)
                        .allowsTightening(true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
                        .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)

                    Spacer(minLength: 0)

                    ControlsView()
                }
                .padding(.horizontal, 0)
                .padding(.bottom, 2)
            }
        }
        .persistentSystemOverlays(.hidden)
    }

    private func flashPhase(now: Date) -> Bool {
        let remaining = model.engine.state.remaining(at: now)
        guard remaining > 0 && remaining <= 5 else { return false }
        let phase = Int(now.timeIntervalSince1970 * 10) % 2
        return phase == 0
    }
}

private struct ControlsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let state = model.engine.state
        let now = model.engine.now
        let remaining = state.remaining(at: now)
        let countingDown = state.isCountingDown(at: now)

        if state.mode == .idle {
            Button {
                model.engine.start()
            } label: {
                Text("Start")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.25))
        } else if countingDown {
            HStack(spacing: 6) {
                smallButton("Sync", enabled: remaining >= 60) { model.engine.sync() }
                smallButton("+1", enabled: true) { model.engine.plusOne() }
            }
        }
        // Count-up: no bottom controls; reset is in the top toolbar.
    }

    @ViewBuilder
    private func smallButton(_ label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.bordered)
        .tint(.white)
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.4)
    }
}
