import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        Form {
            Section {
                ForEach(StartDuration.allCases) { duration in
                    Button {
                        model.engine.setDuration(duration)
                    } label: {
                        HStack {
                            Text(duration.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if model.engine.state.duration == duration {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .disabled(model.engine.state.mode != .idle)
                }
            } header: {
                Text("Starting duration")
            } footer: {
                if model.engine.state.mode != .idle {
                    Text("Reset the timer to change the starting duration.")
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(AppVersion.displayString)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}
