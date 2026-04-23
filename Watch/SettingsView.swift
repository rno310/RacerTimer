import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        List {
            Section("Starting duration") {
                ForEach(StartDuration.allCases) { duration in
                    Button {
                        model.engine.setDuration(duration)
                    } label: {
                        HStack {
                            Text(duration.displayName)
                            Spacer()
                            if model.engine.state.duration == duration {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .disabled(model.engine.state.mode != .idle)
                }
            }
            if model.engine.state.mode != .idle {
                Section {
                    Text("Reset the timer to change the starting duration.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}
