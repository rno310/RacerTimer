import SwiftUI

@main
struct TutastartWatchApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
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
