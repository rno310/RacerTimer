import SwiftUI

@main
struct TutastartApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var model: AppModel
    @State private var showSettings = false

    var body: some View {
        TimerView()
            .overlay(alignment: .topTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(12)
                        .background(.black.opacity(0.25), in: Circle())
                }
                .padding()
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showSettings = false }
                            }
                        }
                }
                .preferredColorScheme(.dark)
            }
    }
}
