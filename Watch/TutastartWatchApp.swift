import SwiftUI

@main
struct TutastartWatchApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var workout = WorkoutSessionController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .onChange(of: model.engine.state.mode) { _, mode in
                    if mode == .running {
                        let fallbackStop = model.engine.state.zeroDate?.addingTimeInterval(120)
                        workout.start(fallbackAutoStopAt: fallbackStop)
                    } else {
                        workout.stop()
                    }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        NavigationStack {
            TimerView()
                .toolbar {
                    if model.engine.state.mode != .idle {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                model.engine.reset()
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
    }
}
