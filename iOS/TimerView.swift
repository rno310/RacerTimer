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

                VStack(spacing: 24) {
                    Spacer()

                    Text(text)
                        .font(.system(size: 160, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(textColor)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 2)
                        .padding(.horizontal, 12)

                    Spacer()

                    ControlsView()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
        }
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
        let running = state.mode == .running

        if state.mode == .idle {
            Button {
                model.engine.start()
            } label: {
                Text("Start")
                    .font(.system(size: 28, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 68)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.2))
            .foregroundColor(.white)
        } else if countingDown {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    bigButton("−1", enabled: remaining >= 60) { model.engine.minusOne() }
                    bigButton("Sync", enabled: remaining >= 60) { model.engine.sync() }
                    bigButton("+1", enabled: true) { model.engine.plusOne() }
                }
                Button(role: .destructive) {
                    model.engine.reset()
                } label: {
                    Text("Reset")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
        } else if running {
            Button(role: .destructive) {
                model.engine.reset()
            } label: {
                Text("Reset")
                    .font(.system(size: 24, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 68)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.2))
            .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private func bigButton(_ label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 24, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 64)
        }
        .buttonStyle(.bordered)
        .tint(.white)
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.4)
    }
}
